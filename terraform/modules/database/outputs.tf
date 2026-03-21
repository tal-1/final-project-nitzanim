output "db_endpoint" {
  description = "The connection endpoint for the PostgreSQL database"
  # RDS returns the endpoint in the format address:port. We usually just want the address.
  value       = split(":", aws_db_instance.main.endpoint)[0] 
}

output "cache_endpoint" {
  description = "The connection endpoint for ElastiCache Valkey"
  value       = aws_elasticache_replication_group.main.primary_endpoint_address
}

output "db_password_secret_arn" {
  description = "The ARN of the database password in Secrets Manager"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "django_secret_key_arn" {
  description = "The ARN of the Django secret key in Secrets Manager"
  value       = aws_secretsmanager_secret.django_secret.arn
}
