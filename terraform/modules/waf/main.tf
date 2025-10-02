# WAF for Cognito
resource "aws_wafv2_web_acl" "cognito" {
  count = var.create_cognito_waf ? 1 : 0

  name  = "${var.env_prefix}cognito-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IPAllowList"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.allowed[0].arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "IPAllowList"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env_prefix}CognitoWAF"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_ip_set" "allowed" {
  count = var.create_cognito_waf ? 1 : 0

  name               = "${var.env_prefix}allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.allowed_ip_ranges
}

# WAF for Published API
resource "aws_wafv2_web_acl" "published_api" {
  name  = "${var.env_prefix}published-api-waf"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "IPAllowList"
    priority = 1

    action {
      block {}
    }

    statement {
      not_statement {
        statement {
          ip_set_reference_statement {
            arn = aws_wafv2_ip_set.api_allowed.arn
          }
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "APIIPAllowList"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.env_prefix}PublishedAPIWAF"
    sampled_requests_enabled   = true
  }
}

resource "aws_wafv2_ip_set" "api_allowed" {
  name               = "${var.env_prefix}api-allowed-ips"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.api_allowed_ip_ranges
}
