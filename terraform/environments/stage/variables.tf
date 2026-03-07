# when running 'terraform plan' or 'terraform apply' commands in the terminal without providing a value for vpc_cidr or domain_name (since they don't have a default value), Terraform will actually pause and ask to type one in

variable "environment" {
  description = "The name of the environment (e.g., dev, stage, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "domain_name" {
  description = "The root domain name for the application (e.g., status.exampledomain.com)"
  type        = string
}
