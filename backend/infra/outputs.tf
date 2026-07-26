output "registry-url" {
    value = aws_ecr_repository.ecr-repository-images.repository_url
}

output "alb-url" {
    value = aws_alb.alb-backend.dns_name
}

output "s3-url" {
  value = aws_s3_bucket_website_configuration.s3-website.website_endpoint
}