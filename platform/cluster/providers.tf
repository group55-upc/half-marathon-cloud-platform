terraform {
  required_providers {
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

provider "kubernetes" {
  # Llegim directament el kubeconfig que ja tens funcionant localment
  # (~/.kube/config, generat amb "aws eks update-kubeconfig"), en lloc
  # de reconstruir host/cluster_ca_certificate/exec des dels atributs
  # del recurs aws_eks_cluster.
  config_path    = pathexpand("~/.kube/config")
  config_context   = try("arn:aws:eks:us-east-1:614151790300:cluster/marathon-cluster-eks", "")
}

provider "helm" {
  kubernetes {
    config_path    = pathexpand("~/.kube/config")
    config_context   = try("arn:aws:eks:us-east-1:614151790300:cluster/marathon-cluster-eks", "")
  }
}