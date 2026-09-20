resource "aws_amplify_app" "amplify-marathon-frontend" {
  name         = "marathon-amplify"
  repository   = "https://github.com/group55-upc/half-marathon-cloud-platform"
  access_token = var.amplify-repository-token

  build_spec = file("${path.module}/../../frontend/amplify/amplify.yml")

  custom_rule {
    source = "/<*>"
    status = "404"
    target = "/index.html"
  }

  tags = local.tags
}


resource "aws_amplify_domain_association" "domain" {
  app_id      = aws_amplify_app.amplify-marathon-frontend.id
  domain_name = aws_route53_zone.fpcmarathon-subzone.name

  sub_domain {
    branch_name = aws_amplify_branch.marathon-main.branch_name
    prefix      = "cloud" 
  }

  certificate_settings {
    type = "AMPLIFY_MANAGED"
  }

   depends_on = [aws_route53_zone.fpcmarathon-subzone]
}


resource "aws_amplify_branch" "marathon-main" {
  app_id      = aws_amplify_app.amplify-marathon-frontend.id
  branch_name = "main"

  enable_auto_build = true
}

