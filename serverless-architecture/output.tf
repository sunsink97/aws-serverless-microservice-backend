output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.microservice_chat_bot_s3_distribution.domain_name
  description = "Cloudfront URL"
}