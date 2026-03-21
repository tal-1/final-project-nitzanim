# Fetch the official AWS Managed Prefix List for CloudFront
data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

# ==========================================
# 1. SECURITY GROUP SHELLS (No Rules Yet)
# ==========================================

resource "aws_security_group" "alb" {
  name        = "${local.sg_name_prefix}-alb"
  description = "ALB Security Group - Restricted to CloudFront"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${local.sg_name_prefix}-alb" })
}

resource "aws_security_group" "ecs" {
  name        = "${local.sg_name_prefix}-ecs"
  description = "ECS Security Group - Restricted to ALB"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${local.sg_name_prefix}-ecs" })
}

resource "aws_security_group" "rds" {
  name        = "${local.sg_name_prefix}-rds"
  description = "RDS Security Group - Restricted to ECS"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${local.sg_name_prefix}-rds" })
}

resource "aws_security_group" "cache" {
  name        = "${local.sg_name_prefix}-cache"
  description = "ElastiCache (Valkey) SG - Restricted to ECS"
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = "${local.sg_name_prefix}-cache" })
}

# ==========================================
# 2. STRICT INGRESS & EGRESS RULES
# ==========================================

# --- ALB Rules ---
resource "aws_vpc_security_group_ingress_rule" "alb_http_cf" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from CloudFront"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https_cf" {
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from CloudFront"
  prefix_list_id    = data.aws_ec2_managed_prefix_list.cloudfront.id
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "alb_to_ecs" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Outbound only to ECS on Port 8000"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}

# --- ECS Rules ---
resource "aws_vpc_security_group_ingress_rule" "ecs_from_alb" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Inbound only from ALB on Port 8000"
  referenced_security_group_id = aws_security_group.alb.id
  from_port                    = 8000
  to_port                      = 8000
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_rds" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Outbound to RDS on Port 5432"
  referenced_security_group_id = aws_security_group.rds.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_cache" {
  security_group_id            = aws_security_group.ecs.id
  description                  = "Outbound to ElastiCache on Port 6379"
  referenced_security_group_id = aws_security_group.cache.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "cache_from_ecs" {
  security_group_id            = aws_security_group.cache.id
  description                  = "Allow inbound ElastiCache traffic from ECS"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_internet_https" {
  security_group_id = aws_security_group.ecs.id
  description       = "Outbound HTTPS to Internet (For ECR Image Pulls)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_dns_tcp" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow DNS Resolution (TCP)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "ecs_to_dns_udp" {
  security_group_id = aws_security_group.ecs.id
  description       = "Allow DNS Resolution (UDP)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 53
  to_port           = 53
  ip_protocol       = "udp"
}

# --- RDS Rules ---
resource "aws_vpc_security_group_ingress_rule" "rds_from_ecs" {
  security_group_id            = aws_security_group.rds.id
  description                  = "Inbound from ECS only"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
}
# (No egress rules defined for RDS = No outbound traffic allowed!)

# --- ElastiCache Rules ---
resource "aws_vpc_security_group_ingress_rule" "cache_from_ecs" {
  security_group_id            = aws_security_group.cache.id
  description                  = "Inbound from ECS only"
  referenced_security_group_id = aws_security_group.ecs.id
  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
}
# (No egress rules defined for Cache = No outbound traffic allowed!)
