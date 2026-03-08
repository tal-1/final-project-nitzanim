variable "environment" {
  description = "The environment name (e.g., dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where security groups will be created"
  type        = string
}

variable "tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
