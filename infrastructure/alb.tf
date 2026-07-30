## ALB ##

resource "aws_alb" "alb-backend" {
  name                  = "alb-backend"
  internal              = false
  load_balancer_type    = "application"
  security_groups       = [aws_security_group.sg-alb-ecs.id]
  subnets               = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_alb_target_group" "alb-tg-backend" {
  name                  = "tg-backend"
  port                  = 5000
  protocol              = "HTTP"
  target_type           = "ip"
  vpc_id                = aws_vpc.vpc.id
}

resource "aws_alb_listener" "alb-listener-backend" {
  load_balancer_arn     = aws_alb.alb-backend.arn
  port                  = "80"
  protocol              = "HTTP"

  default_action {
    type                = "forward"
    target_group_arn    = aws_alb_target_group.alb-tg-backend.arn
  }
}
