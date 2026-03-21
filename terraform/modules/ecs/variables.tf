variable "environment" {
  description = "The environment name"
  type        = string
}

variable "private_subnets" {
  description = "List of private subnet IDs where the containers will run"
  type        = list(string)
}

variable "ecs_security_group" {
  description = "The ID of the ECS Security Group"
  type        = string
}

variable "target_group_arn" {
  description = "The ARN of the ALB Target Group"
  type        = string
}

variable "db_endpoint" {
  description = "The endpoint URL of the RDS database"
  type        = string
}

variable "cache_endpoint" {
  description = "The endpoint URL of the ElastiCache cluster"
  type        = string
}

# We need these to give the Execution Role strict, Least-Privilege access!
variable "db_password_secret_arn" {
  description = "The ARN of the database password in Secrets Manager"
  type        = string
}

variable "django_secret_key_arn" {
  description = "The ARN of the Django Secret Key in Secrets Manager"
  type        = string
}

variable "container_image" {
  description = "The Docker image URL to run (e.g., from ECR)"
  type        = string
  default     = "nginx:latest" # We will use a placeholder until you push your real Django image
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}

variable "db_host" {
  description = "The endpoint URL of the RDS instance"
  type        = string
}

variable "db_name" {
  description = "The name of the database"
  type        = string
}

variable "db_user" {
  description = "The database username"
  type        = string
}

variable "redis_host" {
  description = "The endpoint URL of the Valkey/Redis cluster"
  type        = string
}
