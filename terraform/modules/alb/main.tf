# 1. The Application Load Balancer itself
resource "aws_lb" "main" {
  name               = local.alb_name
  internal           = false  # false = internet-facing, and cloudfront is on the internet
  load_balancer_type = "application"
  security_groups    = [var.security_group_id]
  subnets            = var.public_subnets

  tags = merge(var.tags, { Name = local.alb_name })
}

# 2. The Target Group (The logical grouping of your Django containers)
resource "aws_lb_target_group" "app" {
  name        = local.tg_name
  port        = 8000 # The port Gunicorn/Django will run on
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip" # REQUIRED for AWS Fargate

  # The ALB will constantly ping this path to make sure the app hasn't crashed
  health_check {
    path                = "/" # Change to "/health/" if you build a specific health endpoint
    healthy_threshold   = 3
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200-399" # Considers the app healthy if it returns a 200 OK
  }

  tags = merge(var.tags, { Name = local.tg_name })
}

# 3. The Listener (The rule that tells the ALB what to do with incoming traffic)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Default action: Forward all traffic to the Target Group
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
