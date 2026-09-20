terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.35.0"
    }
  }
  required_version = ">= 1.10.0"
}

provider "aws" {
  region = var.region
}

variable "region" {
	type = string
	default = "us-east-1"
} 

resource "aws_s3_bucket" "s3-website" {
  bucket        = "cloudupc-marathon-website"
  force_destroy = true
  tags          = local.tags
  object_lock_enabled = false
}

locals {
  tags = {
    Project     = "Marathon"
    Environment = "dev"
    Group       = "grupo 5"
  }
}



# https://github.com/hashicorp/terraform-provider-aws/issues/7550
# https://stackoverflow.com/questions/70257559/error-after-creating-s3-bucket-with-terraform