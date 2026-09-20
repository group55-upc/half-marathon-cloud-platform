resource "aws_route53_zone" "fpcmarathon-subzone" {
  name = var.route53-zone-name
  tags = local.tags
}


resource "aws_route53_record" "alb-cluster-alias" {
  zone_id = aws_route53_zone.fpcmarathon-subzone.zone_id
  name    = "api.fpcmarathon.upcnet.es"
  type    = "A"

  alias {
    name                   = aws_alb.alb-cluster.dns_name
    zone_id                = aws_alb.alb-cluster.zone_id
    evaluate_target_health = true
  }
}


resource "aws_route53_record" "alb-cert-validation" {
  for_each = {
    for dvo in aws_acm_certificate.alb-cluster-cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.fpcmarathon-subzone.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 300
}







