resource "aws_amplify_app" "amplify-frontend" {
  name          = "marathon-amplify"
  repository    = "https://github.com/group55-upc/half-marathon-cloud-platform"
  access_token  = var.amplify-repository-token

    build_spec = file("${path.module}/../frontend/amplify/amplify.yml")

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  tags = local.tags
}


resource "aws_amplify_branch" "main" {
  app_id        = aws_amplify_app.amplify-frontend.id
  branch_name   = "main"

  enable_auto_build = true
}

