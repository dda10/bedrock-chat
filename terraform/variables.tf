variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "bedrock_region" {
  description = "AWS region where Bedrock is available"
  type        = string
  default     = "us-east-1"
}

variable "env_name" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = ""
}

variable "self_sign_up_enabled" {
  description = "Allow users to self sign up"
  type        = bool
  default     = true
}

variable "allowed_signup_email_domains" {
  description = "List of allowed email domains for signup"
  type        = list(string)
  default     = []
}

variable "enable_websocket" {
  description = "Enable WebSocket streaming"
  type        = bool
  default     = false
}

variable "websocket_lambda_image_uri" {
  description = "Docker image URI for WebSocket Lambda"
  type        = string
  default     = ""
}

variable "enable_cross_region_inference" {
  description = "Enable Bedrock cross-region inference"
  type        = bool
  default     = false
}

variable "enable_bot_store" {
  description = "Enable bot store feature"
  type        = bool
  default     = true
}

variable "enable_bot_store_replicas" {
  description = "Enable replicas for bot store OpenSearch"
  type        = bool
  default     = false
}

variable "allowed_ip_ranges" {
  description = "Allowed IP ranges for Cognito WAF"
  type        = list(string)
  default     = []
}

variable "api_allowed_ip_ranges" {
  description = "Allowed IP ranges for Published API WAF"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "workspace_name" {
  description = "HCP Terraform workspace name"
  type        = string
}

variable "enable_usage_analysis" {
  description = "Enable usage analytics"
  type        = bool
  default     = false
}

variable "enable_orchestration" {
  description = "Enable orchestration"
  type        = bool
  default     = false
}

variable "enable_waf" {
  description = "Enable WAF"
  type        = bool
  default     = false
}

variable "enable_codebuild" {
  description = "Enable CodeBuild"
  type        = bool
  default     = false
}
