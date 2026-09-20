
resource "helm_release" "aws-lb-controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  set {
    name  = "clusterName"
    value = var.eks-cluster-name
  }
  set {
    name  = "region"
    value = "us-east-1"
  }
  set {
    name  = "vpcId"
    value = var.vpc-id
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
}

