variable "environment" {
  description = "The environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "private_subnets" {
  description = "A list of private subnet IDs for the databases"
  type        = list(string)
}

variable "rds_sg_id" {
  description = "The Security Group ID for RDS"
  type        = string
}

variable "cache_sg_id" {
  description = "The Security Group ID for ElastiCache"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
