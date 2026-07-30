## ENDPOINTS ##

# Endpoints per poder accedir a S3 i DynamoDB a través de la xarxa privada

resource "aws_vpc_endpoint" "endpoint-s3" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.private.id]
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-dynamodb" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type   = "Gateway"
  route_table_ids     = [aws_route_table.private.id]
  tags                = local.tags
}

# Endpoints per poder comunicar ECS amb ECR

resource "aws_vpc_endpoint" "endpoint-ecr-api" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-ecr-dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

# Endpoint per poder enviar els logs desde ECS

resource "aws_vpc_endpoint" "endpoint-logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}