output "registry-url" {
  value = aws_ecr_repository.ecr-repository-images.repository_url
}

output "alb-url" {
  value = aws_alb.alb-cluster.dns_name
}

output "amplify-url" {
  value = aws_amplify_app.amplify-marathon-frontend.default_domain
}

# output "s3-url" {
#   value = aws_s3_bucket_website_configuration.s3-website.website_endpoint
# }

output "route53_nameservers" {
  value = aws_route53_zone.fpcmarathon-subzone.name_servers
}

output "sns-topic" {
  description = "Tema de SNS al que se publican las alarmas"
  value       = var.enable-alarms ? aws_sns_topic.eks-alarms[0].arn : "(alarmas desactivadas)"
}

output "lambda-name" {
  description = "Funcion de importacion periodica de carreras"
  value       = var.enable-lambda ? aws_lambda_function.import-races[0].function_name : "(lambda desactivada)"
}
