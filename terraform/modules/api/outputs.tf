output "api_endpoint" {
  value = aws_apigatewayv2_api.http.api_endpoint
}

output "lambda_function" {
  value = aws_lambda_function.backend
}
