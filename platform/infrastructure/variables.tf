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

# EKS VARIABLES

variable "enable-EKS" {
  description = "Enable the creation of the EKS cluster"
  type        = bool
  default     = false
}

variable "eks-cluster-name" {
  description = "The name of the eks Cluster"
  type        = string
  default     = "marathon-cluster-eks"
}

variable "eks-cluster-version" {
  description = "Kubernetes version of the EKS control plane"
  type        = string
  default     = "1.36"
}

variable "eks-node-instance-type" {
  description = "Instance type for the single EC2 node that runs the AWS Load Balancer Controller"
  type        = string
  default     = "t3.medium"
}

# AMPLIFY

variable "amplify-repository-token" {
  description = "Personal Git PAT Token to access the repository"
  type        = string
  sensitive   = true
}

# OBSERVAVILITY - AUTOSCALING

variable "enable-autoscaling" {
  description = "Crear la politica de escalado automatico del servicio ECS"
  type        = bool
  default     = false
}

variable "eks-autoscaling-cpu-target" {
  description = "Porcentaje de CPU objetivo. Por encima escala, por debajo reduce"
  type        = number
  default     = 60
}

variable "eks-autoscaling-memory-target" {
  description = "Porcentaje de CPU objetivo. Por encima escala, por debajo reduce"
  type        = number
  default     = 60
}

# OBSERVAVILITY - CLOUDWATCH ALARMS

variable "enable-alarms" {
  description = "Crear el tema de SNS y las alarmas de CloudWatch"
  type        = bool
  default     = false
}

variable "eks-alarm-cpu-target" {
  description = "Porcentaje de CPU objetivo. Por encima escala, por debajo reduce"
  type        = number
  default     = 80
}

variable "eks-alarm-memory-target" {
  description = "Porcentaje de CPU objetivo. Por encima escala, por debajo reduce"
  type        = number
  default     = 80
}

# SNS

variable "alert-emails" {
  description = "Correos que recibiran las alarmas. Lista vacia = sin suscripciones"
  type        = list(string)
  default     = []
}

# ROUTE 53

variable "route53-zone-name" {
  description = "Name of the Route53 zone"
  type = string
  default = "fpcmarathon.upcnet.es"
}

# CERT MANAGER

# LOCALS

locals {
  tags = {
    Project     = "Marathon"
    Environment = "dev"
    Group       = "grupo 5"
  }
}