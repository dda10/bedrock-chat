# CodeBuild for dynamic bot creation
resource "aws_codebuild_project" "bot_creation" {
  name         = "${var.env_prefix}bot-creation"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "S3"
    location  = "${var.source_bucket}/source.zip"
    buildspec = "buildspec_bot.yml"
  }
}

# CodeBuild for API publishing
resource "aws_codebuild_project" "api_publish" {
  name         = "${var.env_prefix}api-publish"
  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:7.0"
    type                        = "LINUX_CONTAINER"
    privileged_mode             = true
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "S3"
    location  = "${var.source_bucket}/source.zip"
    buildspec = "buildspec_api.yml"
  }
}

resource "aws_iam_role" "codebuild" {
  name = "${var.env_prefix}codebuild-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "codebuild.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "codebuild" {
  role = aws_iam_role.codebuild.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "${var.source_bucket_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:*",
          "iam:*",
          "lambda:*",
          "apigateway:*",
          "bedrock:*",
          "opensearchserverless:*"
        ]
        Resource = "*"
      }
    ]
  })
}
