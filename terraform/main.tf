terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  cloud {
    organization = "anhdd01"

    workspaces {
      name = "bedrock-chat-test"
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

module "auth" {
  source = "./modules/auth"

  env_prefix           = local.env_prefix
  account_id           = data.aws_caller_identity.current.account_id
  self_sign_up_enabled = var.self_sign_up_enabled
  cloudfront_domain    = module.frontend.cloudfront_domain_name
}

module "frontend" {
  source = "./modules/frontend"

  env_prefix                           = local.env_prefix
  frontend_bucket_id                   = module.storage.frontend_bucket.id
  frontend_bucket_arn                  = module.storage.frontend_bucket.arn
  frontend_bucket_regional_domain_name = module.storage.frontend_bucket.bucket_regional_domain_name
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
  table_access_role_arn   = module.database.table_access_role.arn
}
