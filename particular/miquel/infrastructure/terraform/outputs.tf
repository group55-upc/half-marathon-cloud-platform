# ============================================================
# DYNAMODB OUTPUTS
# ============================================================

output "dynamodb_table_name" {
  description = "Name of the DynamoDB races table."
  value       = aws_dynamodb_table.races.name
}

output "dynamodb_table_arn" {
  description = "ARN of the DynamoDB races table."
  value       = aws_dynamodb_table.races.arn
}

output "seeded_races_count" {
  description = "Number of races initially loaded into DynamoDB."
  value       = length(local.races)
}

# ============================================================
# NETWORK OUTPUTS
# ============================================================

output "vpc_id" {
  description = "ID of the VPC created for the Half Marathon platform."
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "ID of the public subnet hosting the backend EC2 instance."
  value       = aws_subnet.public.id
}

output "public_route_table_id" {
  description = "ID of the public route table."
  value       = aws_route_table.public.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway attached to the VPC."
  value       = aws_internet_gateway.main.id
}

output "backend_security_group_id" {
  description = "ID of the Security Group assigned to the backend EC2 instance."
  value       = aws_security_group.backend.id
}

output "dynamodb_vpc_endpoint_id" {
  description = "ID of the DynamoDB Gateway VPC Endpoint."
  value       = aws_vpc_endpoint.dynamodb.id
}

# ============================================================
# EC2 OUTPUTS
# ============================================================

output "backend_instance_id" {
  description = "ID of the backend EC2 instance."
  value       = aws_instance.backend.id
}

output "backend_private_ip" {
  description = "Private IP address of the backend EC2 instance."
  value       = aws_instance.backend.private_ip
}

output "backend_public_ip" {
  description = "Public IPv4 address of the backend EC2 instance."
  value       = aws_instance.backend.public_ip
}

output "backend_public_dns" {
  description = "Public DNS name of the backend EC2 instance."
  value       = aws_instance.backend.public_dns
}

# ============================================================
# BACKEND APPLICATION OUTPUTS
# ============================================================

output "backend_api_url" {
  description = "Base URL of the Half Marathon backend API."
  value       = "http://${aws_instance.backend.public_ip}:${var.backend_port}"
}

output "backend_health_url" {
  description = "Health check URL of the Half Marathon backend API."
  value       = "http://${aws_instance.backend.public_ip}:${var.backend_port}/health"
}

output "backend_races_url" {
  description = "URL used to retrieve the races from the backend API."
  value       = "http://${aws_instance.backend.public_ip}:${var.backend_port}/races"
}

output "backend_ssh_command" {
  description = "SSH command to connect to the backend EC2 instance."
  value       = "ssh -i ${var.private_key_path} ec2-user@${aws_instance.backend.public_ip}"
}

# ============================================================
# AUTOMATED DEPLOYMENT OUTPUT
# ============================================================

output "backend_deployment_id" {
  description = "ID of the Terraform resource that deployed the backend application."
  value       = terraform_data.backend_deploy.id
}
