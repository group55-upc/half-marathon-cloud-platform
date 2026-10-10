## ENDPOINTS ##

resource "aws_vpc_endpoint" "endpoint-s3" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = local.tags
}

resource "aws_vpc_endpoint" "endpoint-dynamodb" {
  vpc_id            = aws_vpc.vpc.id
  service_name      = "com.amazonaws.us-east-1.dynamodb"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = local.tags
}

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

resource "aws_vpc_endpoint" "endpoint-sts" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.sts"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "endpoint-ec2" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.ec2"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-monitoring" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.monitoring"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-secretmanager" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-cognito" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.cognito-idp"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}
