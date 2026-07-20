# ============================================================
# LOCAL BACKEND PACKAGE
# ============================================================
#
# Terraform creates a ZIP package from the local backend
# directory before deploying it to the EC2 instance.
#
# The following content is excluded:
# - local environment variables;
# - installed dependencies;
# - Git metadata;
# - temporary npm files.

data "archive_file" "backend" {
  type        = "zip"
  source_dir  = abspath(var.backend_source_dir)
  output_path = "${path.module}/backend-deployment.zip"

  excludes = [
    ".env",
    "node_modules",
    ".git",
    ".gitignore",
    "npm-debug.log"
  ]
}
