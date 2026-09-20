## EKS ##

resource "aws_eks_cluster" "eks-cluster-one" {
  count    = var.enable-EKS ? 1 : 0
  name     = var.eks-cluster-name
  role_arn = data.aws_iam_role.lab-role.arn
  version  = var.eks-cluster-version

  bootstrap_self_managed_addons = true

  vpc_config {
    subnet_ids              = aws_subnet.private[*].id
    security_group_ids      = [aws_security_group.sg-eks-cluster-one.id]
    endpoint_private_access = true
    endpoint_public_access  = true
  }

   access_config {
     authentication_mode = "API_AND_CONFIG_MAP"
   }

  tags = local.tags
}


resource "aws_eks_node_group" "worker-nodes-cluster-one" {
  count           = var.enable-EKS ? 1 : 0
  cluster_name    = aws_eks_cluster.eks-cluster-one[0].name
  node_group_name = "eks-worker-nodes"
  node_role_arn   = data.aws_iam_role.lab-role.arn
  subnet_ids      = aws_subnet.private[*].id

  instance_types = [var.eks-node-instance-type]
  ami_type = "AL2023_x86_64_STANDARD"

  launch_template {
    id      = aws_launch_template.worker-node[0].id
    version = aws_launch_template.worker-node[0].latest_version
  }

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 5
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_eks_cluster.eks-cluster-one,
    aws_eks_access_policy_association.student-admin,
    aws_vpc_endpoint.endpoint-ecr-api,
    aws_vpc_endpoint.endpoint-ecr-dkr,
    aws_vpc_endpoint.endpoint-s3,
    aws_vpc_endpoint.endpoint-logs,
    aws_vpc_endpoint.endpoint-ec2,
    aws_vpc_endpoint.sts,
    aws_security_group.sg-vpc-endpoints
  ]
}


resource "aws_launch_template" "worker-node" {
  count       = var.enable-EKS ? 1 : 0
  name_prefix = "eks-worker-node-"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }

}

## CLUSTER ADD-ONS ##

resource "aws_eks_addon" "cloudwatch-observability-cluster" {
  count        = var.enable-EKS ? 1 : 0
  cluster_name = aws_eks_cluster.eks-cluster-one[0].name
  addon_name   = "amazon-cloudwatch-observability"
  depends_on   = [aws_eks_node_group.worker-nodes-cluster-one]
}

## CLUSTER ACCESS ##

# Accés al cluster per l'usuari de las credenciasl de terrafom
resource "aws_eks_access_entry" "student-user" {
  count         = var.enable-EKS ? 1 : 0
  cluster_name  = aws_eks_cluster.eks-cluster-one[0].name
  principal_arn = local.caller_role_arn
}


# Permisos d'admin per al usuari de les credenciasls de terraform
resource "aws_eks_access_policy_association" "student-admin" {
  count         = var.enable-EKS ? 1 : 0
  cluster_name  = aws_eks_cluster.eks-cluster-one[0].name
  principal_arn = local.caller_role_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

locals {
  caller_role_name = element(split("/", data.aws_caller_identity.current.arn), 1)
  caller_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.caller_role_name}"
}

