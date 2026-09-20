## SG ##

# Security Group que correspon al Aplication Load Balancer
resource "aws_security_group" "sg-alb-cluster" {
  name        = "eks-alb-sg"
  description = "Allow traffic to Application Load Balancer"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

# Security Group que correspon als vpc endpoint
resource "aws_security_group" "sg-vpc-endpoints" {
  name        = "vpc-endpoints-sg"
  description = "Allow HTTPS from EKS tasks to VPC endpoints"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description     = "HTTPS from EKS pods"
    from_port       = 443
    to_port         = 443
    protocol        = "TCP"
    security_groups = [aws_security_group.sg-eks-cluster-one.id]
  }

  ingress {
    description = "HTTPS from nodes"
    from_port = 443
    to_port = 443
    protocol = "TCP"
    security_groups = [aws_eks_cluster.eks-cluster-one[0].vpc_config[0].cluster_security_group_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags

  depends_on = [ aws_eks_cluster.eks-cluster-one ]
}

# Security Group que correspon al clúster EKS / Control Plane
resource "aws_security_group" "sg-eks-cluster-one" {
  name        = "eks-cluster-sg"
  description = "Allow traffic to EKS pods (Fargate) and cluster control plane"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Crontrol Plane traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.tags
}

## SG RULES ##

# Norma del sg de la data plane del clúster EKS
resource "aws_security_group_rule" "rule-sg-pods-from-alb" {
  count                    = var.enable-EKS ? 1 : 0
  type                     = "ingress"
  from_port                = 0 
  to_port                  = 65535 
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.eks-cluster-one[0].vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.sg-alb-cluster.id
  description              = "ALB to pods (actual node/pod SG)"
}


# resource "aws_security_group_rule" "rule-sg-vpc-endpoints" {
#   count                    = var.enable-EKS ? 1 : 0
#   type                     = "ingress"
#   from_port                = 443
#   to_port                  = 443
#   protocol                 = "tcp"
#   security_group_id        = aws_security_group.sg-vpc-endpoints.id
#   source_security_group_id = aws_eks_cluster.eks-cluster-one[0].vpc_config[0].cluster_security_group_id
#   description              = "HTTPS from nodes"
# }

