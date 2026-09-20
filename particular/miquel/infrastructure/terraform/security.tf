# ============================================================
# BACKEND EC2 SECURITY GROUP
# ============================================================

resource "aws_security_group" "backend" {
  name        = "${var.project_name}-backend-sg-${var.environment}"
  description = "Security group for the temporary Express backend EC2 instance"
  vpc_id      = aws_vpc.main.id

  # ----------------------------------------------------------
  # SSH
  # ----------------------------------------------------------
  #
  # Allows SSH access only from the public IP configured in
  # terraform.tfvars as allowed_cidr.

  ingress {
    description = "SSH access from administrator public IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # ----------------------------------------------------------
  # EXPRESS BACKEND API
  # ----------------------------------------------------------
  #
  # Allows the local Angular frontend and curl tests to access
  # the Express backend only from the configured public IP.

  ingress {
    description = "Express API access from local frontend"
    from_port   = var.backend_port
    to_port     = var.backend_port
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  # ----------------------------------------------------------
  # OUTBOUND TRAFFIC
  # ----------------------------------------------------------
  #
  # Required so the EC2 instance can:
  # - download Node.js and npm dependencies;
  # - access package repositories;
  # - communicate with AWS services.
  #
  # DynamoDB traffic will use the Gateway VPC Endpoint because
  # the endpoint adds a more specific route to the route table.

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-backend-sg-${var.environment}"
  }
}
