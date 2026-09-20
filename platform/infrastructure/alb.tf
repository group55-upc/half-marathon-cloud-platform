## ALB ##

resource "aws_alb" "alb-cluster" {
  name               = "alb-cluster"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg-alb-cluster.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_alb_target_group" "alb-tg-cluster" {
  name        = "tg-cluster"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.vpc.id
}

resource "aws_alb_listener" "alb-http-listener" {
  load_balancer_arn = aws_alb.alb-cluster.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-tg-cluster.arn
  }
}

resource "aws_alb_listener" "alb-https-listener" {
  load_balancer_arn = aws_alb.alb-cluster.arn
  port              = "443"
  protocol          = "HTTPS"

  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06" 
  certificate_arn   = aws_acm_certificate_validation.alb-cluster-cert.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.alb-tg-cluster.arn
  }
}
