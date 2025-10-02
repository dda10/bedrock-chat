output "frontend_url" {
  description = "CloudFront distribution URL"
  value       = module.frontend.cloudfront_domain_name
}

output "api_endpoint" {
  description = "API Gateway endpoint"
  value       = module.api.api_endpoint
}

output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = module.auth.user_pool.id
}

output "document_bucket" {
  description = "S3 bucket for documents"
  value       = module.storage.document_bucket.bucket
}

output "knowledge_base_id" {
  description = "Bedrock Knowledge Base ID"
  value       = module.bedrock.knowledge_base_id
}

output "frontend_bucket_name" {
  description = "Frontend S3 bucket name"
  value       = module.storage.frontend_bucket.bucket
}
