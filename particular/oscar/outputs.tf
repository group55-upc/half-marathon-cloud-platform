output "vpc_id" {
  value       = aws_vpc.main.id
  description = "ID de la VPC"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "IDs de las subredes públicas"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "IDs de las subredes privadas"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.media_bucket.id
  description = "Nombre único del bucket S3"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.recorridos.name
  description = "Nombre de la tabla DynamoDB"
}