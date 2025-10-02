resource "aws_s3_bucket" "document" {
  bucket        = "${var.env_prefix}bedrock-chat-docs-${var.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "document" {
  bucket                  = aws_s3_bucket.document.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_cors_configuration" "document" {
  bucket = aws_s3_bucket.document.id
  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["PUT", "GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket" "frontend" {
  bucket        = "${var.env_prefix}bedrock-chat-frontend-${var.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
