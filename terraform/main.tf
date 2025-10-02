terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  env_prefix = var.env_name != "" ? "${var.env_name}-" : ""
}

data "aws_caller_identity" "current" {}

module "storage" {
  source = "./modules/storage"

  env_prefix = local.env_prefix
  account_id = data.aws_caller_identity.current.account_id
}

module "database" {
  source = "./modules/database"

  env_prefix = local.env_prefix
  account_id = data.aws_caller_identity.current.account_id
}

module "frontend" {
  source = "./modules/frontend"

  env_prefix                           = local.env_prefix
  frontend_bucket_id                   = module.storage.frontend_bucket.id
  frontend_bucket_arn                  = module.storage.frontend_bucket.arn
  frontend_bucket_regional_domain_name = module.storage.frontend_bucket.bucket_regional_domain_name
}

module "auth" {
  source = "./modules/auth"

  env_prefix           = local.env_prefix
  account_id           = data.aws_caller_identity.current.account_id
  self_sign_up_enabled = var.self_sign_up_enabled
  cloudfront_domain    = module.frontend.cloudfront_domain_name
}

module "bedrock" {
  source = "./modules/bedrock"

  env_prefix          = local.env_prefix
  bedrock_region      = var.bedrock_region
  document_bucket_arn = module.storage.document_bucket.arn
}

module "api" {
  source = "./modules/api"

  env_prefix              = local.env_prefix
  bedrock_region          = var.bedrock_region
  lambda_zip_path         = "${path.module}/backend.zip"
  conversation_table_name = module.database.conversation_table.name
  conversation_table_arn  = module.database.conversation_table.arn
  bot_table_name          = module.database.bot_table.name
  bot_table_arn           = module.database.bot_table.arn
  document_bucket_name    = module.storage.document_bucket.bucket
  document_bucket_arn     = module.storage.document_bucket.arn
  user_pool_id            = module.auth.user_pool.id
  user_pool_client_id     = module.auth.user_pool_client.id
}

module "websocket" {
  source = "./modules/websocket"
  count  = var.enable_websocket ? 1 : 0

  env_prefix                    = local.env_prefix
  lambda_image_uri              = var.websocket_lambda_image_uri
  user_pool_id                  = module.auth.user_pool.id
  user_pool_client_id           = module.auth.user_pool_client.id
  user_pool_arn                 = module.auth.user_pool.arn
  bedrock_region                = var.bedrock_region
  conversation_table_name       = module.database.conversation_table.name
  bot_table_name                = module.database.bot_table.name
  table_access_role_arn         = module.database.table_access_role.arn
  large_message_bucket          = module.storage.large_message_bucket.bucket
  websocket_session_table_name  = module.database.websocket_session_table.name
  enable_cross_region_inference = var.enable_cross_region_inference
}

module "bot_store" {
  source = "./modules/bot-store"
  count  = var.enable_bot_store ? 1 : 0

  env_prefix              = local.env_prefix
  bot_table_arn           = module.database.bot_table.arn
  conversation_table_arn  = module.database.conversation_table.arn
  enable_replicas         = var.enable_bot_store_replicas
}

module "usage_analysis" {
  source = "./modules/usage-analysis"
  count  = var.enable_usage_analysis ? 1 : 0

  env_prefix              = local.env_prefix
  conversation_table_arn  = module.database.conversation_table.arn
}

module "orchestration" {
  source = "./modules/orchestration"
  count  = var.enable_orchestration ? 1 : 0

  env_prefix               = local.env_prefix
  bot_table_stream_arn     = module.database.bot_table.stream_arn
  update_status_lambda_arn = module.api.update_status_lambda_arn
}

module "waf" {
  source = "./modules/waf"
  count  = var.enable_waf ? 1 : 0

  env_prefix             = local.env_prefix
  create_cognito_waf     = length(var.allowed_ip_ranges) > 0
  allowed_ip_ranges      = var.allowed_ip_ranges
  api_allowed_ip_ranges  = var.api_allowed_ip_ranges
}

module "codebuild" {
  source = "./modules/codebuild"
  count  = var.enable_codebuild ? 1 : 0

  env_prefix        = local.env_prefix
  source_bucket     = module.storage.source_bucket.bucket
  source_bucket_arn = module.storage.source_bucket.arn
}
