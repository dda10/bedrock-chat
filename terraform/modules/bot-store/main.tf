# Bot Store - OpenSearch Serverless for bot search
resource "aws_opensearchserverless_collection" "bot_store" {
  name             = "${var.env_prefix}bot-store"
  type             = "SEARCH"
  standby_replicas = var.enable_replicas ? "ENABLED" : "DISABLED"

  depends_on = [
    aws_opensearchserverless_security_policy.encryption,
    aws_opensearchserverless_security_policy.network,
    aws_opensearchserverless_access_policy.data
  ]
}

resource "aws_opensearchserverless_security_policy" "encryption" {
  name = "${var.env_prefix}bot-store-encryption"
  type = "encryption"
  policy = jsonencode({
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.env_prefix}bot-store"]
    }]
    AWSOwnedKey = true
  })
}

resource "aws_opensearchserverless_security_policy" "network" {
  name = "${var.env_prefix}bot-store-network"
  type = "network"
  policy = jsonencode([{
    Rules = [{
      ResourceType = "collection"
      Resource     = ["collection/${var.env_prefix}bot-store"]
    }]
    AllowFromPublic = true
  }])
}

resource "aws_opensearchserverless_access_policy" "data" {
  name = "${var.env_prefix}bot-store-access"
  type = "data"
  policy = jsonencode([{
    Rules = [
      {
        ResourceType = "collection"
        Resource     = ["collection/${var.env_prefix}bot-store"]
        Permission   = ["aoss:*"]
      },
      {
        ResourceType = "index"
        Resource     = ["index/${var.env_prefix}bot-store/*"]
        Permission   = ["aoss:*"]
      }
    ]
    Principal = [aws_iam_role.osis.arn]
  }])
}

# S3 bucket for OSIS export
resource "aws_s3_bucket" "osis_export" {
  bucket_prefix = "${var.env_prefix}osis-export"
}

resource "aws_s3_bucket_public_access_block" "osis_export" {
  bucket                  = aws_s3_bucket.osis_export.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Role for OSIS
resource "aws_iam_role" "osis" {
  name = "${var.env_prefix}osis-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "osis-pipelines.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "osis" {
  role = aws_iam_role.osis.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeTable",
          "dynamodb:DescribeContinuousBackups",
          "dynamodb:ExportTableToPointInTime",
          "dynamodb:DescribeExport",
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator"
        ]
        Resource = [
          var.bot_table_arn,
          "${var.bot_table_arn}/export/*",
          "${var.bot_table_arn}/stream/*",
          var.conversation_table_arn,
          "${var.conversation_table_arn}/export/*",
          "${var.conversation_table_arn}/stream/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:AbortMultipartUpload"
        ]
        Resource = "${aws_s3_bucket.osis_export.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "aoss:APIAccessAll",
          "aoss:BatchGetCollection",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      }
    ]
  })
}

# OSIS Pipeline for Bot table
resource "aws_osis_pipeline" "bot" {
  pipeline_name = "${var.env_prefix}bot-pipeline"
  min_units     = 1
  max_units     = 4

  pipeline_configuration_body = jsonencode({
    version = "2"
    "dynamodb-pipeline" = {
      source = {
        dynamodb = {
          acknowledgments = true
          tables = [{
            table_arn = var.bot_table_arn
            stream = {
              start_position = "LATEST"
            }
            export = {
              s3_bucket = aws_s3_bucket.osis_export.bucket
              s3_region = data.aws_region.current.name
            }
          }]
          aws = {
            sts_role_arn = aws_iam_role.osis.arn
            region       = data.aws_region.current.name
          }
        }
      }
      sink = [{
        opensearch = {
          hosts                  = [aws_opensearchserverless_collection.bot_store.collection_endpoint]
          index                  = "${var.env_prefix}bot"
          document_id            = "$${getMetadata(\"primary_key\")}"
          action                 = "$${getMetadata(\"opensearch_action\")}"
          document_version       = "$${getMetadata(\"document_version\")}"
          document_version_type  = "external"
          aws = {
            sts_role_arn = aws_iam_role.osis.arn
            region       = data.aws_region.current.name
            serverless   = true
          }
        }
      }]
    }
  })
}

# OSIS Pipeline for Conversation table
resource "aws_osis_pipeline" "conversation" {
  pipeline_name = "${var.env_prefix}conversation-pipeline"
  min_units     = 1
  max_units     = 4

  pipeline_configuration_body = jsonencode({
    version = "2"
    "dynamodb-pipeline" = {
      source = {
        dynamodb = {
          acknowledgments = true
          tables = [{
            table_arn = var.conversation_table_arn
            stream = {
              start_position = "LATEST"
            }
            export = {
              s3_bucket = aws_s3_bucket.osis_export.bucket
              s3_region = data.aws_region.current.name
            }
          }]
          aws = {
            sts_role_arn = aws_iam_role.osis.arn
            region       = data.aws_region.current.name
          }
        }
      }
      processor = [
        {
          parse_json = {
            source      = "MessageMap"
            destination = "parsed_message_map"
          }
        },
        {
          add_entries = {
            entries = [{
              key   = "messages"
              value = []
            }]
          }
        },
        {
          map_to_list = {
            source       = "parsed_message_map"
            target       = "messages"
            exclude_keys = []
            key_name     = "id"
          }
        },
        {
          delete_entries = {
            with_keys = [
              "IsLargeMessage",
              "TotalPrice",
              "ShouldContinue",
              "LastMessageId",
              "MessageMap",
              "parsed_message_map"
            ]
          }
        }
      ]
      sink = [{
        opensearch = {
          hosts                  = [aws_opensearchserverless_collection.bot_store.collection_endpoint]
          index                  = "${var.env_prefix}conversation"
          index_type             = "custom"
          template_type          = "index-template"
          document_id            = "$${getMetadata(\"primary_key\")}"
          action                 = "$${getMetadata(\"opensearch_action\")}"
          document_version       = "$${getMetadata(\"document_version\")}"
          document_version_type  = "external"
          aws = {
            sts_role_arn = aws_iam_role.osis.arn
            region       = data.aws_region.current.name
            serverless   = true
          }
        }
      }]
    }
  })
}

data "aws_region" "current" {}
