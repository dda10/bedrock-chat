# IAM Role for table access (used by Lambda for row-level access control)
resource "aws_iam_role" "table_access" {
  name = "${var.env_prefix}bedrock-chat-table-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        AWS = "arn:aws:iam::${var.account_id}:root"
      }
    }]
  })
}

resource "aws_iam_role_policy" "table_access" {
  role = aws_iam_role.table_access.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Resource = [
          aws_dynamodb_table.conversation.arn,
          "${aws_dynamodb_table.conversation.arn}/index/*",
          aws_dynamodb_table.bot.arn,
          "${aws_dynamodb_table.bot.arn}/index/*"
        ]
      }
    ]
  })
}
