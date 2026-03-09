output "custom_domain_url" {
  description = "The final custom domain URL"
  value       = aws_route53_record.cloudfront_alias.fqdn
}
