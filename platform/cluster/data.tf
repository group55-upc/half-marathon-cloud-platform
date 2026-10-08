data "aws_ecr_repository" "ecr-repository" {
    name = var.ecr-repository-name
}

data "aws_alb_target_group" "cluster-target-group" {
    name = var.alb-tg-cluster-name
}

data "aws_eks_cluster" "marathon-eks-cluster" {
  name = var.eks-cluster-name
}