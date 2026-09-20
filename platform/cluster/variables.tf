# INFRASTRUCTURE RELATED VARIABLES #
# MUST BE THE SAME AS THE REAL INFRASTRUCTURE #

variable "vpc-id" {
  description = "The id of main vpc"
  type        = string
  default     = "vpc-059df13e793544feb"
}

variable "eks-cluster-name" {
  description = "The name of the eks Cluster"
  type        = string
  default     = "marathon-cluster-eks"
}

variable "ecr-repository" {
  description = "The URL of the ECR"
  type        = string
  default     = "614151790300.dkr.ecr.us-east-1.amazonaws.com/container-image-repository"
}

variable "alb-cluster-arn" {
  description = "The arn of the alb"
  type        = string
  default     = "arn:aws:elasticloadbalancing:us-east-1:614151790300:targetgroup/tg-cluster/3cb482b21d9296ea"
}


# MARATHON K8S APP #

variable "enable-marathon-app" {
  description = "Crear el tema de SNS y las alarmas de CloudWatch"
  type        = bool
  default     = false
}

variable "namespace-marathon-app" {
  description = "Kubernetes namespace where the app (Fargate) runs"
  type        = string
  default     = "marathon"
}




# LOCALS

locals {
  tags = {
    Project     = "Marathon"
    Environment = "dev"
    Group       = "grupo 5"
  }
}