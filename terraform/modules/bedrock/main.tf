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
    time_sleep.wait_for_collection
  ]
}

resource "time_sleep" "wait_for_collection" {
  create_duration = "60s"

  depends_on = [
    aws_opensearchserverless_collection.kb,
    aws_opensearchserverless_access_policy.kb
  ]
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
    }]
  })
}

resource "aws_iam_role_policy" "kb" {
  role = aws_iam_role.kb.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:ListBucket"]
        Resource = [
          var.document_bucket_arn,
          "${var.document_bucket_arn}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "arn:aws:bedrock:${var.bedrock_region}::foundation-model/amazon.titan-embed-text-v2:0"
      },
      {
        Effect   = "Allow"
        Action   = ["aoss:APIAccessAll"]
        Resource = aws_opensearchserverless_collection.kb.arn
      }
    ]
  })
}

# OpenSearch Policies
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
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.env_prefix}bedrock-chat-kb"]
      Permission   = ["aoss:*"]
    }, {
      ResourceType = "index"
      Resource     = ["index/${var.env_prefix}bedrock-chat-kb/*"]
      Permission   = ["aoss:*"]
    }]
    Principal = [aws_iam_role.kb.arn]
  }])
}
