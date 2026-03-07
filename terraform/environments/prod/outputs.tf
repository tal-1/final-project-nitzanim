output "frontend_url" {
  description = "The free CloudFront URL to access the Status Page"
  value       = module.frontend.cloudfront_domain_name
}

output "alb_dns_name" {
  description = "The DNS name of the Application Load Balancer (for backend testing)"
  value       = module.alb.alb_dns_name
}
