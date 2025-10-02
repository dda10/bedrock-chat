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

output "user_pool_client_id" {
  description = "Cognito User Pool Client ID"
  value       = module.auth.user_pool_client.id
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

output "deploy_frontend_command" {
  description = "Command to deploy frontend (run locally)"
  value       = <<-EOT
    export VITE_APP_API_ENDPOINT="${module.api.api_endpoint}"
    export VITE_APP_WS_ENDPOINT=""
    export VITE_APP_USER_POOL_ID="${module.auth.user_pool.id}"
    export VITE_APP_USER_POOL_CLIENT_ID="${module.auth.user_pool_client.id}"
    export VITE_APP_REGION="${var.aws_region}"
    export VITE_APP_USE_STREAMING="false"
    export FRONTEND_BUCKET="${module.storage.frontend_bucket.bucket}"
    bash deploy-frontend.sh
  EOT
}
