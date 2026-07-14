## XARXA

resource "aws_vpc" "vpc" {
  cidr_block            = var.vpc-cidr
  enable_dns_hostnames  = true
  enable_dns_support    = true
  tags                  = local.tags
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.aws-availability-zones[0]
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 1)
  map_public_ip_on_launch = true 
  tags                    = local.tags
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = var.aws-availability-zones[0]
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 8, 2)
  map_public_ip_on_launch = false
  tags                    = local.tags
}

resource "aws_internet_gateway" "igw" {
  vpc_id  = aws_vpc.vpc.id
  tags    = local.tags
}

resource "aws_route_table" "public" {
  vpc_id         = aws_vpc.vpc.id
  route {
    cidr_block   = "0.0.0.0/0"
    gateway_id   = aws_internet_gateway.igw.id
  }
  tags           = local.tags
}

resource "aws_route_table_association" "public" {
  route_table_id = aws_route_table.public.id
  subnet_id      = aws_subnet.public.id  
}


# DYNAMODB

resource "aws_dynamodb_table" "table-races" {
  name = "races"
  hash_key = "id"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "id"
    type = "S"
  }

}

# ECR (Registry)

resource "aws_ecr_repository" "image-repository" {
    name = "container-image-repository"
    force_delete = true
}

output "registry-url" {
    value = aws_ecr_repository.image-repository.repository_url
}




# PARAFERNALIA PER CREAR EL CLUSTER DE ECS, funciona de la següent manera
# 1. cluster -> entorn lògic on s'executen els contenidors
# 2. task definition -> definició de la tasca on s'executen els contenidors, l'equivalent a un pod de k8s
# 3. Service -> monitora i s'encarrega de que estiguin les còpies que indiquin. l'equivalent a un deploymenty de k8s


resource "aws_ecs_cluster" "cluster-one" {
    count = var.enable-ECS ? 1 : 0
    name = "half-marathon-cluster"
}


data "aws_iam_role" "lab-role" {
  name = "LabRole"
}

resource "aws_ecs_task_definition" "task-one" {
  count = var.enable-ECS ? 1 : 0
  family                   = "half-marathon"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = data.aws_iam_role.lab-role.arn
  task_role_arn            = data.aws_iam_role.lab-role.arn

  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = "${aws_ecr_repository.image-repository.repository_url}:v1.0"  # <- OPA AMB EL TAG
      cpu       = 0
      essential = true
      
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
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


resource "aws_ecs_service" "service-one" {
  count = var.enable-ECS ? 1 : 0
  name = "half-marathon-service"
  cluster = aws_ecs_cluster.cluster-one[count.index].id
  task_definition = aws_ecs_task_definition.task-one[count.index].id
  desired_count = 1
  launch_type = "FARGATE"

  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.public.id  ]
    security_groups  = [aws_security_group.sg-service[count.index].id]
  }
}

# SG DEL SERVICE DE ECS

resource "aws_security_group" "sg-service" {
  count = var.enable-ECS ? 1 : 0
  name        = "service_sg"
  description = "Allow traffic to service"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "Service security group"
    from_port       = 5000
    to_port         = 5000
    protocol        = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





