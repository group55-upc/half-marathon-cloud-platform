resource "aws_amplify_app" "marathon-app-amplify-frontend" {
  count = var.enable-marathon-app ? 1 : 0
  name         = "marathon-amplify"
  repository   = "https://github.com/group55-upc/half-marathon-cloud-platform"
  access_token = var.marathon-app-amplify-repository-token

  build_spec = file("${path.module}/../../marathon-app/frontend/amplify/amplify.yml")

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  tags = local.tags
}


resource "aws_amplify_domain_association" "domain" {
  count = var.enable-marathon-app ? 1 : 0
  app_id      = aws_amplify_app.marathon-app-amplify-frontend[0].id
  domain_name = aws_route53_zone.fpcmarathon-subzone.name

  sub_domain {
    branch_name = aws_amplify_branch.marathon-app-main[0].branch_name
    prefix      = "cloud"
  }

  certificate_settings {
    type = "AMPLIFY_MANAGED"
  }

  depends_on = [aws_route53_zone.fpcmarathon-subzone]
}


resource "aws_amplify_branch" "marathon-app-main" {
  count = var.enable-marathon-app ? 1 : 0
  app_id      = aws_amplify_app.marathon-app-amplify-frontend[0].id
  branch_name = "main"

  enable_auto_build = true
}

resource "aws_amplify_branch" "marathon-app-dev" {
  count = var.enable-marathon-app ? 1 : 0
  app_id      = aws_amplify_app.marathon-app-amplify-frontend[0].id
  branch_name = "dev"

  enable_auto_build = true
}

