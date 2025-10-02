variable "env_prefix" {
  type = string
}

variable "bedrock_region" {
  type = string
}

variable "lambda_zip_path" {
  type = string
}

variable "conversation_table_name" {
  type = string
}

variable "conversation_table_arn" {
  type = string
}

variable "bot_table_name" {
  type = string
}

variable "bot_table_arn" {
  type = string
}

variable "document_bucket_name" {
  type = string
}

variable "document_bucket_arn" {
  type = string
}

variable "user_pool_id" {
  type = string
}

variable "user_pool_client_id" {
  type = string
}

variable "table_access_role_arn" {
  type = string
}
