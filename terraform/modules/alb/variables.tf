variable "environment" {
  description = "The environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "public_subnets" {
  description = "A list of public subnet IDs where the ALB will be placed"
  type        = list(string)
}

variable "security_group_id" {
  description = "The ID of the ALB Security Group"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
