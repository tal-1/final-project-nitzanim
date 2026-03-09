variable "domain_name" {
  description = "The custom domain name (e.g., status.exampledomain.com)"
  type        = string
}

variable "cloudfront_domain_name" {
  description = "The auto-generated URL of the CloudFront distribution"
  type        = string
}

variable "cloudfront_zone_id" {
  description = "The Route53 Zone ID of the CloudFront distribution"
  type        = string
}

variable "tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
}
