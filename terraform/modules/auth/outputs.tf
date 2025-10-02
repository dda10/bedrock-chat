output "user_pool" {
  value = aws_cognito_user_pool.main
}

output "user_pool_client" {
  value = aws_cognito_user_pool_client.main
}

output "user_pool_domain" {
  value = aws_cognito_user_pool_domain.main
}
