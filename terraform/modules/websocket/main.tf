# WebSocket API for streaming responses
resource "aws_apigatewayv2_api" "websocket" {
  name                       = "${var.env_prefix}bedrock-chat-ws"
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id      = aws_apigatewayv2_api.websocket.id
  name        = "dev"
  auto_deploy = true
}

# Lambda for WebSocket handler
resource "aws_lambda_function" "handler" {
  function_name = "${var.env_prefix}websocket-handler"
  role          = aws_iam_role.handler.arn
  package_type  = "Image"
  image_uri     = var.lambda_image_uri
  timeout       = 900
  memory_size   = 512

  environment {
    variables = {
      ACCOUNT                               = data.aws_caller_identity.current.account_id
      REGION                                = data.aws_region.current.name
      USER_POOL_ID                          = var.user_pool_id
      CLIENT_ID                             = var.user_pool_client_id
      BEDROCK_REGION                        = var.bedrock_region
      CONVERSATION_TABLE_NAME               = var.conversation_table_name
      BOT_TABLE_NAME                        = var.bot_table_name
      TABLE_ACCESS_ROLE_ARN                 = var.table_access_role_arn
      LARGE_MESSAGE_BUCKET                  = var.large_message_bucket
      WEBSOCKET_SESSION_TABLE_NAME          = var.websocket_session_table_name
      ENABLE_BEDROCK_CROSS_REGION_INFERENCE = var.enable_cross_region_inference
    }
  }
}

# IAM Role for WebSocket handler
resource "aws_iam_role" "handler" {
  name = "${var.env_prefix}websocket-handler-role"

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

resource "aws_iam_role_policy" "handler" {
  role = aws_iam_role.handler.id

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
        Action   = ["sts:AssumeRole"]
        Resource = var.table_access_role_arn
      },
      {
        Effect   = "Allow"
        Action   = ["bedrock:*"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = ["cognito-idp:AdminListGroupsForUser"]
        Resource = var.user_pool_arn
      },
      {
        Effect   = "Allow"
        Action   = ["execute-api:ManageConnections"]
        Resource = "${aws_apigatewayv2_api.websocket.execution_arn}/*"
      }
    ]
  })
}

# Routes
resource "aws_apigatewayv2_integration" "connect" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.handler.invoke_arn
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

resource "aws_apigatewayv2_integration" "default" {
  api_id           = aws_apigatewayv2_api.websocket.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.handler.invoke_arn
}

resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.websocket.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.default.id}"
}

resource "aws_lambda_permission" "websocket" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket.execution_arn}/*"
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
