output "cloudfront_distribution" {
  value = aws_cloudfront_distribution.main
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.main.domain_name
}
