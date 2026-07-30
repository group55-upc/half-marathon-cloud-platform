## SG ##

# Security Group que correspon al trafic de ECS als vpc endpoint

resource "aws_security_group" "sg-vpc-endpoints" {
  name              = "vpc-endpoints-sg"
  description       = "Allow HTTPS from ECS tasks to VPC endpoints"
  vpc_id            = aws_vpc.vpc.id

  ingress {
    description     = "HTTPS from ECS service"
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    security_groups = [aws_security_group.sg-ecs-service.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags              = local.tags
}

# Security Group que correspon al Service del ECS

resource "aws_security_group" "sg-ecs-service" {
  name              = "ecs-service-sg"
  description       = "Allow traffic to service"
  vpc_id            = aws_vpc.vpc.id

  ingress {
    description     = "Service security group"
    from_port       = 5000
    to_port         = 5000
    protocol        = "TCP"
    security_groups = [aws_security_group.sg-alb-ecs.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags              = local.tags
}

# Security Group que correspon al Aplication Load Balancer del ECS

resource "aws_security_group" "sg-alb-ecs" {
  name              = "ecs-alb-sg"
  description       = "Allow traffic to Application Load Balancer"
  vpc_id            = aws_vpc.vpc.id

  ingress {
    description     = "Application Load Balancer security group"
    from_port       = 80
    to_port         = 80
    protocol        = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description     = "Application Load Balancer security group"
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags              = local.tags
}