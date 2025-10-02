terraform {
  required_providers {
    opensearch = {
      source  = "opensearch-project/opensearch"
      version = "= 2.2.0"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# OpenSearch Serverless Policies
resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.env_prefix}bedrock-kb-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.env_prefix}bedrock-chat-kb"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.env_prefix}bedrock-kb-network"
  type = "network"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.env_prefix}bedrock-chat-kb"]
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_access_policy" "kb" {
  name = "${var.env_prefix}bedrock-kb-access"
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "index"
        Resource     = ["index/${var.env_prefix}bedrock-chat-kb/*"]
        Permission   = ["aoss:CreateIndex", "aoss:DeleteIndex", "aoss:DescribeIndex", "aoss:ReadDocument", "aoss:UpdateIndex", "aoss:WriteDocument"]
      },
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.env_prefix}bedrock-chat-kb"]
        Permission   = ["aoss:CreateCollectionItems", "aoss:DescribeCollectionItems", "aoss:UpdateCollectionItems"]
      }
    ]
    Principal = [aws_iam_role.kb.arn, data.aws_caller_identity.current.arn]
  }])
}

# OpenSearch Serverless Collection
resource "aws_opensearchserverless_collection" "kb" {
  name = "${var.env_prefix}bedrock-chat-kb"
  type = "VECTORSEARCH"

  depends_on = [
    aws_opensearchserverless_access_policy.kb,
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network
  ]
}

# OpenSearch Provider
provider "opensearch" {
  url         = aws_opensearchserverless_collection.kb.collection_endpoint
  healthcheck = false
}

# OpenSearch Index
resource "opensearch_index" "kb" {
  name                           = "bedrock-knowledge-base-default-index"
  number_of_shards               = "2"
  number_of_replicas             = "0"
  index_knn                      = true
  index_knn_algo_param_ef_search = "512"
  mappings                       = <<-EOF
    {
      "properties": {
        "bedrock-knowledge-base-default-vector": {
          "type": "knn_vector",
          "dimension": 1024,
          "method": {
            "name": "hnsw",
            "engine": "faiss",
            "parameters": {
              "m": 16,
              "ef_construction": 512
            },
            "space_type": "l2"
          }
        },
        "AMAZON_BEDROCK_METADATA": {
          "type": "text",
          "index": "false"
        },
        "AMAZON_BEDROCK_TEXT_CHUNK": {
          "type": "text",
          "index": "true"
        }
      }
    }
  EOF
  force_destroy                  = true
  depends_on                     = [aws_opensearchserverless_collection.kb]
}

# IAM Role for Knowledge Base
resource "aws_iam_role" "kb" {
  name = "${var.env_prefix}bedrock-kb-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "bedrock.amazonaws.com"
      }
      Condition = {
        StringEquals = {
          "aws:SourceAccount" = data.aws_caller_identity.current.account_id
        }
        ArnLike = {
          "aws:SourceArn" = "arn:aws:bedrock:${var.bedrock_region}:${data.aws_caller_identity.current.account_id}:knowledge-base/*"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy" "kb_model" {
  name = "${var.env_prefix}bedrock-kb-model-policy"
  role = aws_iam_role.kb.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "bedrock:InvokeModel"
      Effect   = "Allow"
      Resource = "arn:aws:bedrock:${var.bedrock_region}::foundation-model/amazon.titan-embed-text-v2:0"
    }]
  })
}

resource "aws_iam_role_policy" "kb_s3" {
  name = "${var.env_prefix}bedrock-kb-s3-policy"
  role = aws_iam_role.kb.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3ListBucketStatement"
        Action = "s3:ListBucket"
        Effect = "Allow"
        Resource = var.document_bucket_arn
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      },
      {
        Sid    = "S3GetObjectStatement"
        Action = "s3:GetObject"
        Effect = "Allow"
        Resource = "${var.document_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "kb_oss" {
  name = "${var.env_prefix}bedrock-kb-oss-policy"
  role = aws_iam_role.kb.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action   = "aoss:APIAccessAll"
      Effect   = "Allow"
      Resource = aws_opensearchserverless_collection.kb.arn
    }]
  })
}

resource "time_sleep" "wait_for_oss_policy" {
  create_duration = "20s"
  depends_on      = [aws_iam_role_policy.kb_oss]
}

# Bedrock Knowledge Base
resource "aws_bedrockagent_knowledge_base" "main" {
  name     = "${var.env_prefix}bedrock-chat-kb"
  role_arn = aws_iam_role.kb.arn

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = "arn:aws:bedrock:${var.bedrock_region}::foundation-model/amazon.titan-embed-text-v2:0"
    }
  }

  storage_configuration {
    type = "OPENSEARCH_SERVERLESS"
    opensearch_serverless_configuration {
      collection_arn    = aws_opensearchserverless_collection.kb.arn
      vector_index_name = "bedrock-knowledge-base-default-index"
      field_mapping {
        vector_field   = "bedrock-knowledge-base-default-vector"
        text_field     = "AMAZON_BEDROCK_TEXT_CHUNK"
        metadata_field = "AMAZON_BEDROCK_METADATA"
      }
    }
  }

  depends_on = [
    aws_iam_role_policy.kb_model,
    aws_iam_role_policy.kb_s3,
    opensearch_index.kb,
    time_sleep.wait_for_oss_policy
  ]
}

# Data Source
resource "aws_bedrockagent_data_source" "s3" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.main.id
  name              = "s3-documents"

  data_source_configuration {
    type = "S3"
    s3_configuration {
      bucket_arn = var.document_bucket_arn
    }
  }
}
