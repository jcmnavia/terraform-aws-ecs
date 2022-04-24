
########################## APPLICATION LOAD BALANCER (ALB) CONFIGURATION ##################################

resource "aws_alb" "application_load_balancer" {
  name               = "${var.project}-${var.environment}-alb" # Naming our load balancer
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = aws_subnet.pub_subnet.*.id
  tags = {
    Name        = "${var.project}-alb"
    Environment = "${var.environment}"
  }
}


########################## TARGET GROUP (TG) CONFIGURATION ##################################

resource "aws_lb_target_group" "target_group" {
  name        = "${var.project}-${var.environment}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.default_vpc.id # Referencing the default VPC
  health_check {
    matcher = "200,301,302"
    path    = "/v1/health"
  }
  tags = {
    Name        = "${var.project}-lb-tg"
    Environment = "${var.environment}"
  }
}

########################## LISTENERS CONFIGURATION ##################################

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_alb.application_load_balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS-1-2-Ext-2018-06"
  certificate_arn   = var.acmarn


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.arn
  }
}
