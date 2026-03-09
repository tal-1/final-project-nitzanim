# 1. Look up the existing Hosted Zone for your domain
# (AWS creates this automatically when you register a domain in Route53)
data "aws_route53_zone" "primary" {
  name         = var.domain_name
  private_zone = false
}

# 2. Create the Alias Record pointing to CloudFront
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = var.domain_name
  type    = local.record_type

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_zone_id
    evaluate_target_health = false # CloudFront health is managed internally by AWS
  }
}
