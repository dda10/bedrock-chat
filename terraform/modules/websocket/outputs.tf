output "websocket_url" {
  value = "${aws_apigatewayv2_api.websocket.api_endpoint}/${aws_apigatewayv2_stage.dev.name}"
}

output "websocket_api_id" {
  value = aws_apigatewayv2_api.websocket.id
}
