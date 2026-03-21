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
