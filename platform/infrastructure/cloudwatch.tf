
## ALARMAS DE CLOUDWATCH ##

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  count               = (var.enable-EKS && var.enable-alarms) ? 1 : 0
  alarm_name          = "eks-dataplane-cpu-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"
  threshold           = var.eks-alarm-cpu-target
  alarm_description   = "Average CPU utilization across EKS worker node ASG is above 80% for 3 consecutive minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.worker-nodes-cluster-one[0].resources[0].autoscaling_groups[0].name
  }

  alarm_actions = [aws_sns_topic.eks-alarms[0].arn]

  tags = local.tags

  depends_on = [aws_eks_cluster.eks-cluster-one]
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  count               = (var.enable-EKS && var.enable-alarms) ? 1 : 0
  alarm_name          = "eks-dataplane-memory-high"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "mem_used_percent"
  namespace           = "CWAgent"
  evaluation_periods  = 2
  period              = 60
  statistic           = "Average"
  threshold           = var.eks-alarm-memory-target
  alarm_description   = "Average memory utilization across EKS worker node ASG is above 80% for 3 consecutive minutes"
  treat_missing_data  = "notBreaching"

  dimensions = {
    AutoScalingGroupName = aws_eks_node_group.worker-nodes-cluster-one[0].resources[0].autoscaling_groups[0].name
  }

  alarm_actions = [aws_sns_topic.eks-alarms[0].arn]

  tags = local.tags

  depends_on = [aws_eks_cluster.eks-cluster-one]
}
