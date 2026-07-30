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
  task_definition     = aws_ecs_task_definition.ecs-task-one[count.index].arn
  desired_count       = var.ecs-service-replicas
  launch_type         = "FARGATE"

  network_configuration {
    assign_public_ip  = false
    subnets           = aws_subnet.private[*].id
    security_groups   = [aws_security_group.sg-ecs-service.id]
  }

  load_balancer {
    container_name    = var.ecs-container-name
    container_port    = var.ecs-container-port
    target_group_arn  = aws_alb_target_group.alb-tg-backend.arn
  }
}

## ECR (Registry) ##

resource "aws_ecr_repository" "ecr-repository-images" {
    name              = var.ecr-name
    force_delete      = true
    tags              = local.tags
}