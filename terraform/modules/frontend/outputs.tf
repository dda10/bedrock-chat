output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.main
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}

output "frontend_bucket_name" {
  value = var.frontend_bucket_id
}
