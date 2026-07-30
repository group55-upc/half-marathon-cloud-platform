# OVERALL VARIABLES

variable "region" {
  description = "The selected AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "aws-availability-zones" {
  description = "List of aws availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

# NETWORK VARIABLES

variable "vpc-cidr" {
  description = "The address range of the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# DYNAMODB VARIABLES

variable "dynamodb-name" {
  description = "The name of the DynamoDB"
  type        = string
  default     = "races" 
}

# ECR VARIABLES

variable "ecr-name" {
  description = "The name of the ECR"
  type        = string
  default     = "container-image-repository" 
}

# ECS VARIABLES

variable "enable-ECS" {
    description = "Enable the creation of the ECS cluster"
    type = bool
    default = false
}

variable "ecs-cluster-name" {
  description = "The name of the ECS Cluster"
  type        = string
  default     = "marathon-cluster" 
}

variable "ecs-task-name" {
  description = "The name of the ECS Task"
  type        = string
  default     = "marathon-task" 
}

variable "ecs-task-cpu" {
  description = "CPU of the ECS Task"
  type        = string
  default     = "512" 
}

variable "ecs-task-memory" {
  description = "Memory of the ECS Task"
  type        = string
  default     = "1024" 
}

variable "ecs-service-name" {
  description = "The name of the ECS Service"
  type        = string
  default     = "marathon-service" 
}

variable "ecs-service-replicas" {
  description = "Replicas of the ECS Service"
  type        = number
  default     = 2 
}

variable "ecs-container-name" {
  description = "The name of the ECS Task container name"
  type        = string
  default     = "backend" 
}

variable "ecs-container-port" {
  description = "The port of the ECS Task container"
  type        = number
  default     = 5000
}

# AMPLIFY

variable "amplify-repository-token" {
  description = "Personal Git PAT Token to access the repository"
  type = string
  sensitive = true
}

# LOCALS

locals {
  tags = {
    Project     = "Marathon"
    Environment = "dev"
    Group       = "grupo 5"
  }
}