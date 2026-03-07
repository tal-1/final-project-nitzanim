output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnets" {
  description = "A list of IDs for the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnets" {
  description = "A list of IDs for the private subnets"
  value       = aws_subnet.private[*].id
}
