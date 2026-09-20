## Data block resources for diferents .tf files

data "aws_caller_identity" "current" {}

data "aws_iam_role" "lab-role" {
  name = "LabRole"
}

data "aws_iam_instance_profile" "lab-instance" {
  name = "LabInstanceProfile"
}