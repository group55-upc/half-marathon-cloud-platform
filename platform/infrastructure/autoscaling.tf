## EKS AUTOSCALING

resource "aws_autoscaling_policy" "eks-dataplane-cpu" {
  count              = (var.enable-EKS && var.enable-autoscaling) ? 1 : 0
  name               = "eks-dataplane-cpu-usage"
  policy_type        = "TargetTrackingScaling"
  autoscaling_group_name      = aws_eks_node_group.worker-nodes-cluster-one[0].resources[0].autoscaling_groups[0].name

  target_tracking_configuration{
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.eks-autoscaling-cpu-target
  }

  estimated_instance_warmup = 180
}

resource "aws_autoscaling_policy" "eks-dataplane-memory" {
  count              = (var.enable-EKS && var.enable-autoscaling) ? 1 : 0
  name                   = "eks-dataplane-memory-usage"
  policy_type            = "TargetTrackingScaling"
  autoscaling_group_name = aws_eks_node_group.worker-nodes-cluster-one[0].resources[0].autoscaling_groups[0].name


  target_tracking_configuration {
    customized_metric_specification {
      metric_name = "mem_used_percent"
      namespace   = "CWAgent"
      statistic   = "Average"

      metric_dimension {
        name  = "AutoScalingGroupName"
        value = aws_eks_node_group.worker-nodes-cluster-one[0].resources[0].autoscaling_groups[0].name
      }
    }
    target_value = var.eks-autoscaling-memory-target
  }

  estimated_instance_warmup = 180
}
