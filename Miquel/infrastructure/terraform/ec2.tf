# ============================================================
# AMAZON LINUX 2023 AMI
# ============================================================

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name = "name"

    values = [
      "al2023-ami-2023.*-x86_64"
    ]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ============================================================
# BACKEND EC2 INSTANCE
# ============================================================

resource "aws_instance" "backend" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.backend.id]
  associate_public_ip_address = true

  key_name             = var.ec2_key_name
  iam_instance_profile = var.ec2_instance_profile_name

  # Require Instance Metadata Service version 2.
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Recreate the instance when the bootstrap configuration changes.
  user_data_replace_on_change = true

  # ----------------------------------------------------------
  # INITIAL EC2 BOOTSTRAP
  # ----------------------------------------------------------
  #
  # This script:
  # - installs curl, unzip and Node.js;
  # - creates the backend installation directory;
  # - stores bootstrap logs for troubleshooting.
  #
  # The application source code will be uploaded separately
  # by Terraform from the local backend directory.

  user_data = <<-EOF
    #!/bin/bash
    set -euxo pipefail

    exec > >(tee -a /var/log/half-marathon-bootstrap.log) 2>&1

    echo "Starting Half Marathon backend EC2 bootstrap"

    dnf update -y
    dnf install -y unzip

    curl -fsSL https://rpm.nodesource.com/setup_22.x | bash -
    dnf install -y nodejs

    mkdir -p /opt/half-marathon-backend
    chown ec2-user:ec2-user /opt/half-marathon-backend
    chmod 755 /opt/half-marathon-backend

    node --version
    npm --version

    echo "EC2 bootstrap completed"
  EOF

  depends_on = [
    aws_route.internet_access,
    aws_route_table_association.public,
    aws_vpc_endpoint.dynamodb,
    aws_dynamodb_table_item.race_seed
  ]

  tags = {
    Name = "${var.project_name}-backend-${var.environment}"
    Role = "backend"
  }
}
