output "registry-url" {
    value = aws_ecr_repository.ecr-repository-images.repository_url
}

output "alb-url" {
    value = aws_alb.alb-backend.dns_name
}