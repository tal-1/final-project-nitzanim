output "alb_sg_id" {
  description = "The ID of the Security Group for the Application Load Balancer"
  value       = aws_security_group.alb.id
}

output "ecs_sg_id" {
  description = "The ID of the Security Group for the ECS/Fargate containers"
  value       = aws_security_group.ecs.id
}

output "rds_sg_id" {
  description = "The ID of the Security Group for the RDS PostgreSQL database"
  value       = aws_security_group.rds.id
}

output "cache_sg_id" {
  description = "The ID of the Security Group for the ElastiCache Valkey cluster"
  value       = aws_security_group.cache.id
}
