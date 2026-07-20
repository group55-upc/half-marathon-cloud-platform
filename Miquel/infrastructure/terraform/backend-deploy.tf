# ============================================================
# DEPLOY LOCAL BACKEND TO EC2
# ============================================================
#
# This Terraform resource:
# - waits for the EC2 bootstrap to finish;
# - uploads the locally generated backend ZIP;
# - installs the Node.js production dependencies;
# - creates the backend environment file;
# - creates and enables a permanent systemd service;
# - validates the backend health endpoint.
#
# The deployment is repeated when:
# - the EC2 instance changes; or
# - any file in the local backend package changes.

resource "terraform_data" "backend_deploy" {
  triggers_replace = [
    aws_instance.backend.id,
    data.archive_file.backend.output_base64sha256
  ]

  # ----------------------------------------------------------
  # SSH CONNECTION
  # ----------------------------------------------------------

  connection {
    type        = "ssh"
    host        = aws_instance.backend.public_ip
    user        = "ec2-user"
    private_key = file(pathexpand(var.private_key_path))
    timeout     = "10m"
  }

  # ----------------------------------------------------------
  # WAIT FOR EC2 BOOTSTRAP
  # ----------------------------------------------------------

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "node --version",
      "npm --version",
      "unzip -v | head -1"
    ]
  }

  # ----------------------------------------------------------
  # UPLOAD BACKEND PACKAGE
  # ----------------------------------------------------------

  provisioner "file" {
    source      = data.archive_file.backend.output_path
    destination = "/tmp/backend-deployment.zip"
  }

  # ----------------------------------------------------------
  # UPLOAD ENVIRONMENT CONFIGURATION
  # ----------------------------------------------------------

  provisioner "file" {
    content = <<-ENV
      AWS_REGION=${var.aws_region}
      DYNAMODB_TABLE_NAME=${aws_dynamodb_table.races.name}
      PORT=${var.backend_port}
    ENV

    destination = "/tmp/half-marathon-backend.env"
  }

  # ----------------------------------------------------------
  # UPLOAD SYSTEMD SERVICE
  # ----------------------------------------------------------

  provisioner "file" {
    content = <<-SERVICE
      [Unit]
      Description=Half Marathon Backend API
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      User=ec2-user
      WorkingDirectory=/opt/half-marathon-backend
      EnvironmentFile=/etc/half-marathon-backend.env
      ExecStart=/usr/bin/node /opt/half-marathon-backend/server.js
      Restart=always
      RestartSec=5

      [Install]
      WantedBy=multi-user.target
    SERVICE

    destination = "/tmp/half-marathon-backend.service"
  }

  # ----------------------------------------------------------
  # INSTALL AND START BACKEND
  # ----------------------------------------------------------

  provisioner "remote-exec" {
    inline = [
      # Stop the previous service if this is a redeployment.
      "sudo systemctl stop half-marathon-backend 2>/dev/null || true",

      # Recreate the application directory.
      "sudo rm -rf /opt/half-marathon-backend",
      "sudo mkdir -p /opt/half-marathon-backend",

      # Extract the backend source code.
      "sudo unzip -o /tmp/backend-deployment.zip -d /opt/half-marathon-backend",

      # Assign ownership to the application user.
      "sudo chown -R ec2-user:ec2-user /opt/half-marathon-backend",

      # Install production dependencies.
      "cd /opt/half-marathon-backend && npm ci --omit=dev",

      # Install the environment file securely.
      "sudo install -o root -g ec2-user -m 0640 /tmp/half-marathon-backend.env /etc/half-marathon-backend.env",

      # Install the systemd service.
      "sudo install -o root -g root -m 0644 /tmp/half-marathon-backend.service /etc/systemd/system/half-marathon-backend.service",

      # Enable and start the permanent backend service.
      "sudo systemctl daemon-reload",
      "sudo systemctl enable half-marathon-backend",
      "sudo systemctl restart half-marathon-backend",

      # Wait up to 60 seconds for the API to become available.
      "for attempt in $(seq 1 20); do curl --fail --silent http://localhost:${var.backend_port}/health && exit 0; echo \"Waiting for backend: attempt $attempt/20\"; sleep 3; done; sudo journalctl -u half-marathon-backend -n 50 --no-pager; exit 1"
    ]
  }

  depends_on = [
    aws_instance.backend,
    aws_vpc_endpoint.dynamodb,
    aws_dynamodb_table_item.race_seed
  ]
}
