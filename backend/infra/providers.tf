terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    # Necesario para empaquetar el codigo de la funcion Lambda en un .zip
    # sin herramientas externas (ver lambda.tf)
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }
  required_version = ">= 1.10.0"
}

provider "aws" {
  region = var.region
} 