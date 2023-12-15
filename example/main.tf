variable "fqdn" {
  default = "barneyparker.com"
}

variable "vpc_id" {}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

#tfsec:ignore:aws-elb-drop-invalid-headers
resource "aws_lb" "testing" {
  name                       = "test-alb"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.testing.id]
  subnets                    = data.aws_subnets.subnets.ids
  enable_deletion_protection = false
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.testing.arn
  port              = "443"
  #tfsec:ignore:aws-elb-http-not-used
  protocol = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.targets_dns.arn
  }
}

resource "aws_lb_target_group" "targets_dns" {
  name        = "fqdn-target"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  tags = {
    FQDN = var.fqdn
  }
}


resource "aws_security_group" "testing" {
  name        = "test-alb-sg"
  description = "Allow inbound traffic from the internet"
  vpc_id      = var.vpc_id
}
