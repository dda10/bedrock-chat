output "cognito_waf_arn" {
  value = var.create_cognito_waf ? aws_wafv2_web_acl.cognito[0].arn : ""
}

output "published_api_waf_arn" {
  value = aws_wafv2_web_acl.published_api.arn
}
