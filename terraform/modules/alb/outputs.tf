output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.main.dns_name
}

output "target_group_arn" {
  description = "The ARN of the Target Group (needed by ECS)"
  value       = aws_lb_target_group.app.arn
}
