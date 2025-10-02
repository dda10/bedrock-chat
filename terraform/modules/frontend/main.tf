resource "aws_cloudfront_origin_access_identity" "main" {
  comment = "${var.env_prefix}Bedrock Chat OAI"
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = var.frontend_bucket_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowCloudFrontAccess"
      Effect = "Allow"
      Principal = {
        AWS = aws_cloudfront_origin_access_identity.main.iam_arn
      }
      Action   = "s3:GetObject"
      Resource = "${var.frontend_bucket_arn}/*"
    }]
  })
}

resource "aws_cloudfront_distribution" "main" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = var.frontend_bucket_regional_domain_name
    origin_id   = "S3-Frontend"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Frontend"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }
}

resource "null_resource" "build_frontend" {
  triggers = {
    api_endpoint        = var.api_endpoint
    user_pool_id        = var.user_pool_id
    user_pool_client_id = var.user_pool_client_id
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../../../frontend
      npm install
      VITE_APP_API_ENDPOINT=${var.api_endpoint} \
      VITE_APP_WS_ENDPOINT=${var.websocket_endpoint} \
      VITE_APP_USER_POOL_ID=${var.user_pool_id} \
      VITE_APP_USER_POOL_CLIENT_ID=${var.user_pool_client_id} \
      VITE_APP_REGION=${var.aws_region} \
      VITE_APP_USE_STREAMING=false \
      npm run build
    EOT
  }

  depends_on = [aws_cloudfront_distribution.main]
}

resource "null_resource" "deploy_frontend" {
  triggers = {
    build_hash = null_resource.build_frontend.id
  }

  provisioner "local-exec" {
    command = "aws s3 sync ${path.module}/../../../frontend/dist s3://${var.frontend_bucket_id}/ --delete"
  }

  depends_on = [null_resource.build_frontend]
}
