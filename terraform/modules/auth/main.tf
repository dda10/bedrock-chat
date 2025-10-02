resource "aws_cognito_user_pool" "main" {
  name = "${var.env_prefix}bedrock-chat-users"

  auto_verified_attributes = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = true
  }

  admin_create_user_config {
    allow_admin_create_user_only = !var.self_sign_up_enabled
  }

  username_configuration {
    case_sensitive = false
  }
}

# User Groups
resource "aws_cognito_user_group" "admin" {
  name         = "Admin"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_group" "creating_bot_allowed" {
  name         = "CreatingBotAllowed"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_group" "publish_allowed" {
  name         = "PublishAllowed"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.env_prefix}bedrock-chat-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  callback_urls = concat(
    ["https://${var.cloudfront_domain}"],
    var.additional_callback_urls
  )

  logout_urls = concat(
    ["https://${var.cloudfront_domain}"],
    var.additional_logout_urls
  )

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "profile"]
  allowed_oauth_flows_user_pool_client = true
  supported_identity_providers         = ["COGNITO"]
}

resource "aws_cognito_user_pool_domain" "main" {
  domain       = "${var.env_prefix}bedrock-chat-${var.account_id}"
  user_pool_id = aws_cognito_user_pool.main.id
}
