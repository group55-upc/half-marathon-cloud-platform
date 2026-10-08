# INFRASTRUCTURE RELATED VARIABLES #
# MUST BE THE SAME AS THE REAL INFRASTRUCTURE #

variable "region" {
  description = "The selected AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

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

variable "ecr-repository-name" {
  description = "The name of the ECR"
  type        = string
  default     = "container-image-repository"
}

variable "alb-tg-cluster-name" {
  description = "The name of the alb"
  type        = string
  default     = "tg-cluster"
}


# MARATHON K8S APP #

variable "enable-marathon-app" {
  description = "Activa la app de marathon-app"
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