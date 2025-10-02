variable "env_prefix" {
  type = string
}

variable "frontend_bucket_id" {
  type = string
}

variable "frontend_bucket_arn" {
  type = string
}

variable "frontend_bucket_regional_domain_name" {
  type = string
}

variable "api_endpoint" {
  type = string
}

variable "websocket_endpoint" {
  type    = string
  default = ""
}

variable "user_pool_id" {
  type = string
}

variable "user_pool_client_id" {
  type = string
}

variable "aws_region" {
  type = string
}
