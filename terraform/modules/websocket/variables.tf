variable "env_prefix" {
  type = string
}

variable "lambda_image_uri" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "user_pool_client_id" {
  type = string
}

variable "user_pool_arn" {
  type = string
}

variable "bedrock_region" {
  type = string
}

variable "conversation_table_name" {
  type = string
}

variable "bot_table_name" {
  type = string
}

variable "table_access_role_arn" {
  type = string
}

variable "large_message_bucket" {
  type = string
}

variable "websocket_session_table_name" {
  type = string
}

variable "enable_cross_region_inference" {
  type    = bool
  default = false
}
