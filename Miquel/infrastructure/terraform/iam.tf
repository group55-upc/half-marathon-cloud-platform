# ============================================================
# IAM CONFIGURATION
# ============================================================
#
# AWS Academy provides the following existing resources:
#
#   Instance Profile: LabInstanceProfile
#   IAM Role:         LabRole
#
# Terraform must not try to create IAM roles, policies or
# instance profiles because the AWS Academy user does not have
# permissions for iam:CreateRole or iam:CreatePolicy.
#
# The EC2 instance will reference the existing instance profile
# through:
#
#   iam_instance_profile = var.ec2_instance_profile_name
#
# No IAM resources are created in this file.
