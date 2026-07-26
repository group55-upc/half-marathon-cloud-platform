## XARXA ##

resource "aws_vpc" "vpc" {
  cidr_block            = var.vpc-cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags                  = local.tags
}

resource "aws_subnet" "public" {
  count                 = length(var.aws-availability-zones)
  vpc_id                = aws_vpc.vpc.id
  availability_zone     = var.aws-availability-zones[count.index]
  cidr_block            = cidrsubnet(aws_vpc.vpc.cidr_block, 8, (count.index))
  tags                  = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id                = aws_vpc.vpc.id
  tags                  = local.tags
}

resource "aws_route_table" "public" {
  vpc_id                = aws_vpc.vpc.id
  route {
    cidr_block          = "0.0.0.0/0"
    gateway_id          = aws_internet_gateway.igw.id
  }
  tags                  = local.tags
}

resource "aws_route_table_association" "public" {
  count                 = 2
  route_table_id        = aws_route_table.public.id
  subnet_id             = aws_subnet.public[count.index].id  
}

resource "aws_subnet" "private" {
  vpc_id                = aws_vpc.vpc.id
  availability_zone     = var.aws-availability-zones[0]
  cidr_block            = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  tags                  = local.tags
}

resource "aws_route_table" "private" {
  vpc_id                = aws_vpc.vpc.id
  tags                  = local.tags
}

resource "aws_route_table_association" "private" {
  subnet_id             = aws_subnet.private.id
  route_table_id        = aws_route_table.private.id
}





## DYNAMODB ##

resource "aws_dynamodb_table" "dynamodb-table-races" {
  name              = var.dynamodb-name
  hash_key          = "id"
  billing_mode      = "PAY_PER_REQUEST"

  attribute {
    name            = "id"
    type            = "S"
  }

  tags              = local.tags
}





## ECR (Registry) ##

resource "aws_ecr_repository" "ecr-repository-images" {
    name              = var.ecr-name
    force_delete      = true
    tags              = local.tags
}





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
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

resource "aws_vpc_endpoint" "endpoint-ecr-dkr" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}

# Endpoint per poder enviar els logs desde ECS

resource "aws_vpc_endpoint" "endpoint-logs" {
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.us-east-1.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private.id]
  security_group_ids  = [aws_security_group.sg-vpc-endpoints.id]
  private_dns_enabled = true
  tags                = local.tags
}




## ECS ##
# 1. cluster -> entorn lògic on s'executen els contenidors
# 2. task definition -> definició de la tasca on s'executen els contenidors, l'equivalent a un pod de k8s
# 3. Service -> monitora i s'encarrega de que estiguin les còpies que indiquin. l'equivalent a un deploymenty de k8s

data "aws_iam_role" "lab-role" {
  name      = "LabRole"
}

resource "aws_ecs_cluster" "ecs-cluster-one" {
    count   = var.enable-ECS ? 1 : 0
    name    = var.ecs-cluster-name
    tags    = local.tags
}

resource "aws_ecs_task_definition" "ecs-task-one" {
  count                    = var.enable-ECS ? 1 : 0
  family                   = var.ecs-task-name
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs-task-cpu
  memory                   = var.ecs-task-memory
  execution_role_arn       = data.aws_iam_role.lab-role.arn
  task_role_arn            = data.aws_iam_role.lab-role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "${var.ecs-container-name}"
      image     = "${aws_ecr_repository.ecr-repository-images.repository_url}:v1.0"  # <- OPA AMB EL TAG
      cpu       = 0
      essential = true
      
      portMappings = [
        {
          containerPort = var.ecs-container-port
          hostPort      = var.ecs-container-port
          protocol      = "tcp"
          name          = "backend-5000-tcp"
          appProtocol   = "http"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/half-marathon"
          "awslogs-create-group"  = "true"
          "awslogs-region"        = "us-east-1"
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}


resource "aws_ecs_service" "ecs-service-one" {
  count               = var.enable-ECS ? 1 : 0
  name                = var.ecs-service-name
  cluster             = aws_ecs_cluster.ecs-cluster-one[count.index].id
  task_definition     = aws_ecs_task_definition.ecs-task-one[count.index].id
  desired_count       = var.ecs-service-replicas
  launch_type         = "FARGATE"

  network_configuration {
    assign_public_ip  = false
    subnets           = [aws_subnet.private.id]
    security_groups   = [aws_security_group.sg-ecs-service.id]
  }

  load_balancer {
    container_name    = var.ecs-container-name
    container_port    = var.ecs-container-port
    target_group_arn  = aws_alb_target_group.alb-tg-backend.arn
  }
}




## ALB ##

resource "aws_alb" "alb-backend" {
  name                  = "lb-backend"
  internal              = false
  load_balancer_type    = "application"
  security_groups       = [aws_security_group.sg-alb-ecs.id]
  subnets               = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_alb_target_group" "alb-tg-backend" {
  name                  = "tg-backend"
  port                  = 5000
  protocol              = "HTTP"
  target_type           = "ip"
  vpc_id                = aws_vpc.vpc.id
}

resource "aws_alb_listener" "alb-listener-backend" {
  load_balancer_arn     = aws_alb.alb-backend.arn
  port                  = "80"
  protocol              = "HTTP"

  default_action {
    type                = "forward"
    target_group_arn    = aws_alb_target_group.alb-tg-backend.arn
  }
}





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