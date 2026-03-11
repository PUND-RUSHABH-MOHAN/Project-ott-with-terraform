output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "ec2_public_ip" {
  description = "WordPress EC2 Public IP"
  value       = aws_instance.wordpress.public_ip
}

output "alb_dns_name" {
  description = "ALB DNS Name - Access WordPress here"
  value       = aws_lb.main.dns_name
}

output "s3_raw_bucket" {
  description = "S3 bucket for raw video uploads"
  value       = aws_s3_bucket.video_raw.bucket
}

output "s3_processed_bucket" {
  description = "S3 bucket for processed videos"
  value       = aws_s3_bucket.video_processed.bucket
}

output "cloudfront_domain" {
  description = "CloudFront domain for video streaming"
  value       = aws_cloudfront_distribution.video_cdn.domain_name
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "cognito_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.wordpress_client.id
}

output "cognito_login_url" {
  description = "Cognito Hosted UI Login URL"
  value       = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${var.aws_region}.amazoncognito.com/login?client_id=${aws_cognito_user_pool_client.wordpress_client.id}&response_type=code&scope=email+openid+profile&redirect_uri=http://${aws_lb.main.dns_name}/"
}

output "wordpress_url" {
  description = "WordPress site URL"
  value       = "http://${aws_lb.main.dns_name}"
}
