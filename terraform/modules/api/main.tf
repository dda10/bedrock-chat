resource "aws_iam_role" "lambda" {
  name = "${var.env_prefix}bedrock-chat-lambda"

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

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda" {
  role = aws_iam_role.lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem", "dynamodb:Query", "dynamodb:Scan"]
        Resource = [
          var.conversation_table_arn,
          var.bot_table_arn,
          "${var.bot_table_arn}/index/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject"]
        Resource = "${var.document_bucket_arn}/*"
      }
    ]
  })
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/../../../backend"
  output_path = "${path.module}/lambda.zip"
  excludes = [
    "node_modules",
    "dist",
    "dev-dist",
    ".venv",
    "__pycache__",
    "cdk.out",
    ".vscode",
    ".DS_Store",
    ".git",
    ".github",
    ".mypy_cache",
    "examples",
    "docs",
    ".env",
    ".env.local",
    ".gitignore",
    "test",
    "tests",
    "embedding_statemachine/pdf_ai_ocr",
    "guardrails"
  ]
}

resource "aws_lambda_function" "backend" {
  filename         = data.archive_file.lambda.output_path
  function_name    = "${var.env_prefix}bedrock-chat-backend"
  role             = aws_iam_role.lambda.arn
  handler          = "run.sh"
  runtime          = "python3.13"
  timeout          = 900
  memory_size      = 1024
  source_code_hash = data.archive_file.lambda.output_base64sha256

  layers = [
    "arn:aws:lambda:${data.aws_region.current.name}:753240598075:layer:LambdaAdapterLayerX86:23"
  ]

  environment {
    variables = {
      CONVERSATION_TABLE_NAME = var.conversation_table_name
      BOT_TABLE_NAME          = var.bot_table_name
      BEDROCK_REGION          = var.bedrock_region
      TABLE_ACCESS_ROLE_ARN   = var.table_access_role_arn
      DOCUMENT_BUCKET         = var.document_bucket_name
      USER_POOL_ID            = var.user_pool_id
      CLIENT_ID               = var.user_pool_client_id
      ACCOUNT                 = data.aws_caller_identity.current.account_id
      REGION                  = data.aws_region.current.name
      AWS_LAMBDA_EXEC_WRAPPER = "/opt/bootstrap"
      PORT                    = "8000"
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

resource "aws_apigatewayv2_api" "http" {
  name          = "${var.env_prefix}bedrock-chat-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["*"]
  }
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.http.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.backend.invoke_arn
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.http.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}
