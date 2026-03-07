# 1. Networking Module
module "networking" {
  source      = "../../modules/networking"
  environment = local.environment
  vpc_cidr    = var.vpc_cidr
  tags        = local.common_tags
}

# 2. Security Module (Security Groups & IAM)
module "security" {
  source      = "../../modules/security"
  environment = local.environment
  vpc_id      = module.networking.vpc_id
  tags        = local.common_tags
}

# 3. ALB Module (Application Load Balancer)
module "alb" {
  source            = "../../modules/alb"
  environment       = local.environment
  vpc_id            = module.networking.vpc_id
  public_subnets    = module.networking.public_subnets
  security_group_id = module.security.alb_sg_id
  tags              = local.common_tags
}

# 4. Database Module (RDS & ElastiCache)
module "database" {
  source               = "../../modules/database"
  environment          = local.environment
  vpc_id               = module.networking.vpc_id
  private_subnets      = module.networking.private_subnets
  db_security_group    = module.security.rds_sg_id
  cache_security_group = module.security.cache_sg_id
  tags                 = local.common_tags
}

# 5. ECS Module (Fargate Cluster & Django App)
module "ecs" {
  source              = "../../modules/ecs"
  environment         = local.environment
  vpc_id              = module.networking.vpc_id
  private_subnets     = module.networking.private_subnets
  ecs_security_group  = module.security.ecs_sg_id
  target_group_arn    = module.alb.target_group_arn
  
  # Passing Database info to the containers
  db_endpoint         = module.database.rds_endpoint
  cache_endpoint      = module.database.cache_endpoint
  tags                = local.common_tags
}

# 6. Frontend Module (S3 Bucket & CloudFront)
module "frontend" {
  source       = "../../modules/frontend"
  environment  = local.environment
  alb_dns_name = module.alb.alb_dns_name
  tags         = local.common_tags
}

/*
# 7. DNS Module (Route53)
module "dns" {
  source                 = "../../modules/dns"
  domain_name            = var.domain_name
  cloudfront_domain_name = module.frontend.cloudfront_domain_name
  cloudfront_zone_id     = module.frontend.cloudfront_zone_id
  tags                   = local.common_tags
}
*/
