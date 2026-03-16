# ==========================================
# 1. S3 Bucket (For Django Static/Media Files)
# ==========================================
# Generate a random string because S3 bucket names MUST be globally unique across all of AWS
resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "static" {
  bucket        = "${var.environment}-django-static-${random_string.bucket_suffix.result}"
  force_destroy = true # Allows Terraform to delete the bucket even if it has files in it during teardown
  tags          = var.tags
}

# ==========================================
# 2. CloudFront Origin Access Control (OAC)
# ==========================================
# This acts as a highly secure "badge" that CloudFront shows S3 to prove it is allowed to read the files
resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "${var.environment}-s3-oac"
  description                       = "OAC for S3 static assets"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# Attaches the policy to the S3 bucket to accept the OAC badge
resource "aws_s3_bucket_policy" "static_access" {
  bucket = aws_s3_bucket.static.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
    # prevents GitHub actions having AdministratorAccess on S3 #
      # --- STATEMENT 1: CloudFront Read Access (OAC) ---
      {
      Effect    = "Allow"
      Principal = { Service = "cloudfront.amazonaws.com" }
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.static.arn}/*"
      Condition = {
        StringEquals = { "AWS:SourceArn" = aws_cloudfront_distribution.main.arn }
      }
    },
    # --- STATEMENT 2: GitHub Actions Write Access ---
    {
        Effect    = "Allow"
        # Notice we construct the ARN using the data.aws_caller_identity below
        Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/github-actions-terraform-role" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.static.arn}/*"
      }
    ]
  })
}

# ==========================================
# 3. CloudFront Distribution
# ==========================================
resource "aws_cloudfront_distribution" "main" {
  enabled         = true
  is_ipv6_enabled = true
  comment         = "${var.environment} Frontend Distribution"
  tags            = var.tags
  web_acl_id      = aws_wafv2_web_acl.main.arn

  # --- ORIGIN 1: The S3 Bucket ---
  origin {
    domain_name              = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id                = local.s3_origin_id
    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  # --- ORIGIN 2: The ALB (Django App) ---
  origin {
    domain_name = var.alb_dns_name
    origin_id   = local.alb_origin_id
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only" # We connect to ALB on Port 80
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- BEHAVIOR 1: Default (Send everything to Django/ALB) ---
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.alb_origin_id
    viewer_protocol_policy = "redirect-to-https"

    # AWS Managed Policy: "CachingDisabled" (We do NOT want to cache dynamic Django views)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" 
    # AWS Managed Policy: "AllViewer" (Forward all headers/cookies to Django so login works)
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3"
  }

  # --- BEHAVIOR 2: Static Files (Send /static/* to S3) ---
  ordered_cache_behavior {
    path_pattern     = "/static/*"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id
    viewer_protocol_policy = "redirect-to-https"

    # AWS Managed Policy: "CachingOptimized" (Cache these heavily to save money/speed)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # SSL Certificate (Using the free, default CloudFront certificate for now)
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

# ==========================================
# 4. WAF (must be in us-east-1)
# ==========================================
resource "aws_wafv2_web_acl" "main" {
  name        = "${var.environment}-cloudfront-waf"
  description = "WAF for CloudFront Distribution"
  scope       = "CLOUDFRONT"

  default_action {
    allow {}
  }

  # AWS Managed Rule: Blocks common vulnerabilities like SQLi and XSS
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1
    
    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "aws-common-rules"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.environment}-waf-metrics"
    sampled_requests_enabled   = true
  }
}

