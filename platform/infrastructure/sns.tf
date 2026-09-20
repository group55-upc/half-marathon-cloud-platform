## SNS: TEMA DE ALERTAS ##

resource "aws_sns_topic" "eks-alarms" {
  count = var.enable-alarms ? 1 : 0
  name  = "eks-cluster-alarms"
  tags  = local.tags
}

resource "aws_sns_topic_subscription" "alertas-correo" {
  for_each  = var.enable-alarms ? toset(var.alert-emails) : toset([])
  topic_arn = aws_sns_topic.eks-alarms[0].arn
  protocol  = "email"
  endpoint  = each.value
}





