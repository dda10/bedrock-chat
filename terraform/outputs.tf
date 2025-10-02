output "frontend_url" {
  description = "CloudFront URL for frontend"
  value       = "https://${module.frontend.cloudfront_domain_name}"
}

output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = module.api.api_endpoint
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.auth.user_pool.id
}

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.auth.user_pool_client.id
}

output "document_bucket" {
  description = "S3 bucket for documents"
  value       = module.storage.document_bucket.bucket
}

output "frontend_bucket" {
  description = "S3 bucket for frontend"
  value       = module.storage.frontend_bucket.bucket
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock.knowledge_base_id
}

output "data_source_id" {
  description = "Bedrock Data Source ID"
  value       = module.bedrock.data_source_id
}
output "websocket_url" {
  value = module.websocket.websocket_url
}

output "bot_store_endpoint" {
  value = var.enable_bot_store ? module.bot_store[0].opensearch_endpoint : null
}

output "usage_analysis_workgroup" {
  value = module.usage_analysis.workgroup_name
}

output "state_machine_arn" {
  value = module.orchestration.state_machine_arn
}

output "cognito_waf_arn" {
  value = module.waf.cognito_waf_arn
}

output "published_api_waf_arn" {
  value = module.waf.published_api_waf_arn
}

output "bot_creation_project" {
  value = module.codebuild.bot_creation_project_name
}

output "api_publish_project" {
  value = module.codebuild.api_publish_project_name
}
