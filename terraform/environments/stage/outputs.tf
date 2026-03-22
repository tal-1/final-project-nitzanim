output "frontend_url" {
  description = "The free CloudFront URL to access the Status Page"
  value       = module.frontend.cloudfront_domain_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer (for backend testing)"
  value       = module.alb.alb_dns_name
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket holding the static files"
  value       = module.frontend.s3_bucket_name
}

output "cloudfront_distribution_id" {
  description = "The ID of the CloudFront distribution"
  value       = module.frontend.cloudfront_distribution_id
}

output "ecs_cluster_name" {
  description = "The name of the ECS cluster"
  value       = module.ecs.cluster_name
}

output "ecs_service_name" {
  description = "The name of the ECS service"
  value       = module.ecs.service_name
}

output "private_subnets" {
  description = "The private subnets for the ECS tasks"
  value       = join(",", module.networking.private_subnets)
}

output "ecs_sg_id" {
  description = "The security group ID for the ECS tasks"
  value       = module.security.ecs_sg_id
}
