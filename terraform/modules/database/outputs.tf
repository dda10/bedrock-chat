output "conversation_table" {
  value = aws_dynamodb_table.conversation
}

output "bot_table" {
  value = aws_dynamodb_table.bot
}

output "websocket_session_table" {
  value = aws_dynamodb_table.websocket_session
}

output "table_access_role" {
  value = aws_iam_role.table_access
}
