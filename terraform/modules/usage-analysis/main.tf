# Usage Analysis - Athena + Glue for analytics
resource "aws_s3_bucket" "ddb_export" {
  bucket_prefix = "${var.env_prefix}ddb-export"
}

resource "aws_s3_bucket_public_access_block" "ddb_export" {
  bucket                  = aws_s3_bucket.ddb_export.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket" "query_results" {
  bucket_prefix = "${var.env_prefix}athena-results"
}

resource "aws_s3_bucket_public_access_block" "query_results" {
  bucket                  = aws_s3_bucket.query_results.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Glue Database
resource "aws_glue_catalog_database" "usage" {
  name = "${var.env_prefix}usage_analysis"
}

# Glue Table for DDB exports
resource "aws_glue_catalog_table" "ddb_export" {
  database_name = aws_glue_catalog_database.usage.name
  name          = "${var.env_prefix}ddb_export"

  table_type = "EXTERNAL_TABLE"

  partition_keys {
    name = "datehour"
    type = "string"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.ddb_export.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat"

    ser_de_info {
      serialization_library = "org.openx.data.jsonserde.JsonSerDe"
    }

    columns {
      name = "Metadata"
      type = "struct<WriteTimestampMicros:struct<N:string>>"
    }

    columns {
      name = "Keys"
      type = "struct<PK:struct<S:string>,SK:struct<S:string>>"
    }

    columns {
      name = "NewImage"
      type = "struct<CreateTime:struct<N:string>,Title:struct<S:string>,BotId:struct<S:string>,TotalPrice:struct<N:decimal(20,10)>>"
    }
  }

  parameters = {
    "projection.enabled"              = "true"
    "projection.datehour.type"        = "date"
    "projection.datehour.range"       = "2023/01/01/00,2123/01/01/00"
    "projection.datehour.format"      = "yyyy/MM/dd/HH"
    "projection.datehour.interval"    = "1"
    "projection.datehour.interval.unit" = "HOURS"
    "storage.location.template"       = "s3://${aws_s3_bucket.ddb_export.bucket}/$${datehour}/AWSDynamoDB/data/"
  }
}

# Athena Workgroup
resource "aws_athena_workgroup" "usage" {
  name = "${var.env_prefix}usage-analysis"

  configuration {
    result_configuration {
      output_location = "s3://${aws_s3_bucket.query_results.bucket}/"
    }
  }
}

# Lambda for DDB export
resource "aws_lambda_function" "export" {
  function_name = "${var.env_prefix}ddb-export"
  role          = aws_iam_role.export.arn
  handler       = "index.handler"
  runtime       = "python3.13"
  timeout       = 60

  filename         = data.archive_file.export_lambda.output_path
  source_code_hash = data.archive_file.export_lambda.output_base64sha256

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.ddb_export.bucket
      TABLE_ARN   = var.conversation_table_arn
    }
  }
}

data "archive_file" "export_lambda" {
  type        = "zip"
  output_path = "${path.module}/export_lambda.zip"

  source {
    content  = <<-EOF
import boto3
import os
from datetime import datetime

def handler(event, context):
    dynamodb = boto3.client('dynamodb')
    table_arn = os.environ['TABLE_ARN']
    bucket = os.environ['BUCKET_NAME']
    
    now = datetime.utcnow()
    s3_prefix = now.strftime('%Y/%m/%d/%H')
    
    response = dynamodb.export_table_to_point_in_time(
        TableArn=table_arn,
        S3Bucket=bucket,
        S3Prefix=s3_prefix,
        ExportFormat='DYNAMODB_JSON'
    )
    
    return {'statusCode': 200, 'body': response['ExportDescription']['ExportArn']}
EOF
    filename = "index.py"
  }
}

resource "aws_iam_role" "export" {
  name = "${var.env_prefix}ddb-export-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "export" {
  role = aws_iam_role.export.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:ExportTableToPointInTime"]
        Resource = var.conversation_table_arn
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject"]
        Resource = "${aws_s3_bucket.ddb_export.arn}/*"
      }
    ]
  })
}

# EventBridge rule to trigger export hourly
resource "aws_cloudwatch_event_rule" "hourly" {
  name                = "${var.env_prefix}hourly-export"
  schedule_expression = "cron(5 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "export" {
  rule      = aws_cloudwatch_event_rule.hourly.name
  target_id = "ExportLambda"
  arn       = aws_lambda_function.export.arn
}

resource "aws_lambda_permission" "eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.export.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.hourly.arn
}
