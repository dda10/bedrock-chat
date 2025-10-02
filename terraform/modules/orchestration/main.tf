# Step Functions for Knowledge Base orchestration
resource "aws_sfn_state_machine" "embedding" {
  name     = "${var.env_prefix}embedding-orchestration"
  role_arn = aws_iam_role.sfn.arn

  definition = jsonencode({
    Comment = "Orchestrate Knowledge Base creation and ingestion"
    StartAt = "ExtractFirstElement"
    States = {
      ExtractFirstElement = {
        Type = "Pass"
        Parameters = {
          "dynamodb.$"       = "$[0].dynamodb"
          "eventID.$"        = "$[0].eventID"
          "eventName.$"      = "$[0].eventName"
          "eventSource.$"    = "$[0].eventSource"
          "eventVersion.$"   = "$[0].eventVersion"
          "awsRegion.$"      = "$[0].awsRegion"
          "eventSourceARN.$" = "$[0].eventSourceARN"
        }
        Next = "UpdateSyncStatusRunning"
      }
      UpdateSyncStatusRunning = {
        Type     = "Task"
        Resource = var.update_status_lambda_arn
        Parameters = {
          "pk.$"               = "$.dynamodb.NewImage.PK.S"
          "sk.$"               = "$.dynamodb.NewImage.SK.S"
          sync_status          = "RUNNING"
          sync_status_reason   = ""
        }
        ResultPath = "$.UpdateResult"
        Next       = "StartIngestionJob"
      }
      StartIngestionJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:bedrockagent:startIngestionJob"
        Parameters = {
          "DataSourceId.$"     = "$.dynamodb.NewImage.DataSourceId.S"
          "KnowledgeBaseId.$"  = "$.dynamodb.NewImage.KnowledgeBaseId.S"
        }
        ResultPath = "$.IngestionJob"
        Next       = "WaitForIngestion"
      }
      WaitForIngestion = {
        Type    = "Wait"
        Seconds = 3
        Next    = "GetIngestionJob"
      }
      GetIngestionJob = {
        Type     = "Task"
        Resource = "arn:aws:states:::aws-sdk:bedrockagent:getIngestionJob"
        Parameters = {
          "DataSourceId.$"     = "$.IngestionJob.IngestionJob.DataSourceId"
          "KnowledgeBaseId.$"  = "$.IngestionJob.IngestionJob.KnowledgeBaseId"
          "IngestionJobId.$"   = "$.IngestionJob.IngestionJob.IngestionJobId"
        }
        ResultPath = "$.IngestionJob"
        Next       = "CheckIngestionStatus"
      }
      CheckIngestionStatus = {
        Type = "Choice"
        Choices = [
          {
            Variable      = "$.IngestionJob.IngestionJob.Status"
            StringEquals  = "COMPLETE"
            Next          = "UpdateSyncStatusSuccess"
          },
          {
            Variable      = "$.IngestionJob.IngestionJob.Status"
            StringEquals  = "FAILED"
            Next          = "UpdateSyncStatusFailed"
          }
        ]
        Default = "WaitForIngestion"
      }
      UpdateSyncStatusSuccess = {
        Type     = "Task"
        Resource = var.update_status_lambda_arn
        Parameters = {
          "pk.$"               = "$.dynamodb.NewImage.PK.S"
          "sk.$"               = "$.dynamodb.NewImage.SK.S"
          sync_status          = "SUCCEEDED"
          sync_status_reason   = "Knowledge base sync succeeded"
        }
        End = true
      }
      UpdateSyncStatusFailed = {
        Type     = "Task"
        Resource = var.update_status_lambda_arn
        Parameters = {
          "pk.$"               = "$.dynamodb.NewImage.PK.S"
          "sk.$"               = "$.dynamodb.NewImage.SK.S"
          sync_status          = "FAILED"
          sync_status_reason   = "Ingestion job failed"
        }
        Next = "FailState"
      }
      FailState = {
        Type  = "Fail"
        Cause = "Knowledge base sync failed"
      }
    }
  })
}

resource "aws_iam_role" "sfn" {
  name = "${var.env_prefix}sfn-embedding-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "sfn" {
  role = aws_iam_role.sfn.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:StartIngestionJob",
          "bedrock:GetIngestionJob"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = var.update_status_lambda_arn
      }
    ]
  })
}

# EventBridge Pipe to trigger Step Functions from DynamoDB stream
resource "aws_pipes_pipe" "bot_sync" {
  name     = "${var.env_prefix}bot-sync-pipe"
  role_arn = aws_iam_role.pipe.arn
  source   = var.bot_table_stream_arn
  target   = aws_sfn_state_machine.embedding.arn

  source_parameters {
    dynamodb_stream_parameters {
      batch_size        = 1
      starting_position = "LATEST"
    }

    filter_criteria {
      filter {
        pattern = jsonencode({
          dynamodb = {
            NewImage = {
              SyncStatus = {
                S = [{ prefix = "QUEUED" }]
              }
            }
          }
        })
      }
    }
  }

  target_parameters {
    step_function_state_machine_parameters {
      invocation_type = "FIRE_AND_FORGET"
    }
  }
}

resource "aws_iam_role" "pipe" {
  name = "${var.env_prefix}pipe-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "pipes.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "pipe" {
  role = aws_iam_role.pipe.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:DescribeStream",
          "dynamodb:GetRecords",
          "dynamodb:GetShardIterator",
          "dynamodb:ListStreams"
        ]
        Resource = var.bot_table_stream_arn
      },
      {
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = aws_sfn_state_machine.embedding.arn
      }
    ]
  })
}
