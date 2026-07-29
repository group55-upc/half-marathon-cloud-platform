output "registry-url" {
    value = aws_ecr_repository.ecr-repository-images.repository_url
}

output "alb-url" {
    value = aws_alb.alb-backend.dns_name
}

output "s3-url" {
  value = aws_s3_bucket_website_configuration.s3-website.website_endpoint
}

output "sns-topic" {
  description = "Tema de SNS al que se publican las alarmas"
  value       = var.enable-alarms ? aws_sns_topic.alertas[0].arn : "(alarmas desactivadas)"
}

output "lambda-name" {
  description = "Funcion de importacion periodica de carreras"
  value       = var.enable-lambda ? aws_lambda_function.import-races[0].function_name : "(lambda desactivada)"
}

output "autoscaling" {
  description = "Rango de escalado automatico del servicio ECS"
  value = (var.enable-ECS && var.enable-autoscaling) ? format(
    "de %d a %d tareas, objetivo %d%% de CPU",
    var.ecs-autoscaling-min,
    var.ecs-autoscaling-max,
    var.ecs-autoscaling-cpu-target
  ) : "(escalado desactivado)"
}