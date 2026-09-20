## ECR (Registry) ##

resource "aws_ecr_repository" "ecr-repository-images" {
    name              = var.ecr-name
    force_delete      = true
    tags              = local.tags
}
