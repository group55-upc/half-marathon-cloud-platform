variable "aws_region" {
  description = "AWS region where the resources will be deployed."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used to identify AWS resources."
  type        = string
  default     = "half-marathon"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "The environment must be dev, test or prod."
  }
}

variable "vpc_cidr" {
  description = "CIDR block for the test VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet."
  type        = string
  default     = "10.20.1.0/24"
}

variable "instance_type" {
  description = "EC2 instance type used for the backend."
  type        = string
  default     = "t3.micro"
}

variable "allowed_cidr" {
  description = "Public IPv4 CIDR allowed to access SSH and the backend API."
  type        = string

  validation {
    condition     = can(cidrnetmask(var.allowed_cidr))
    error_message = "allowed_cidr must be a valid CIDR, for example 155.138.69.74/32."
  }
}

variable "ec2_key_name" {
  description = "Name of the existing EC2 key pair."
  type        = string
  default     = "half-marathon-key"
}

variable "private_key_path" {
  description = "Local path to the private SSH key."
  type        = string
  default     = "~/.ssh/half-marathon-key.pem"
}

variable "ec2_instance_profile_name" {
  description = "Existing IAM instance profile provided by AWS Academy."
  type        = string
  default     = "LabInstanceProfile"
}

variable "backend_port" {
  description = "Port exposed by the Express backend."
  type        = number
  default     = 5000
}

variable "backend_source_dir" {
  description = "Local path to the backend source code, relative to the Terraform directory."
  type        = string
  default     = "../../backend"
}
