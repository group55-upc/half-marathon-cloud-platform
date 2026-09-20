resource "aws_acm_certificate" "alb-cluster-cert" {
  domain_name       = "api.fpcmarathon.upcnet.es"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
  
  tags = local.tags
}


resource "aws_acm_certificate_validation" "alb-cluster-cert" {
  certificate_arn         = aws_acm_certificate.alb-cluster-cert.arn
  validation_record_fqdns = [for record in aws_route53_record.alb-cert-validation : record.fqdn]
}