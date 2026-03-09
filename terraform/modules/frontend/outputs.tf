output "cloudfront_domain_name" {
  description = "The auto-generated URL of the CloudFront distribution"
  value       = aws_cloudfront_distribution.main.domain_name
}

output "cloudfront_zone_id" {
  description = "The Route53 Zone ID of the CloudFront distribution (Needed for DNS)"
  value       = aws_cloudfront_distribution.main.hosted_zone_id
}

output "s3_bucket_name" {
  description = "The name of the S3 bucket holding the static files"
  value       = aws_s3_bucket.static.id
}
