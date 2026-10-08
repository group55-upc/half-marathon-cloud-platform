terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
  required_version = ">= 1.10.0"
}

provider "aws" {
  region = var.region
} 

provider "kubernetes" {
  config_path    = pathexpand("~/.kube/config")
  config_context = data.aws_eks_cluster.marathon-eks-cluster.arn
}

provider "helm" {
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context = data.aws_eks_cluster.marathon-eks-cluster.arn
  }
}