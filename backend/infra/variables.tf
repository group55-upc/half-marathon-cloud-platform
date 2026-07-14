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

# CONTROL VARIABLES

variable "enable-ECS" {
    description = "Enable the creation of the ECS cluster"
    type = bool
    default = false
}

locals {
  tags = {
    Project     = "Marathon"
    Environment = "dev"
    Group       = "grupo 5"
  }
}