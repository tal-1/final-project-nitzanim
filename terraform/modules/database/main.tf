# ==========================================
# 1. Subnet Groups
# ==========================================
resource "aws_db_subnet_group" "main" {
  name       = local.subnet_group_name
  subnet_ids = var.private_subnets
  tags       = merge(var.tags, { Name = local.subnet_group_name })
}

resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.environment}-cache-subnet-group"
  subnet_ids = var.private_subnets
  tags       = merge(var.tags, { Name = "${var.environment}-cache-subnet-group" })
}

# ==========================================
# 2. Random Password Generators & Secrets
# ==========================================
# Generate a random 16-character password for the Database
resource "random_password" "db_password" {
  length  = 16
  special = false # RDS passwords can be picky with special characters
}

# Generate a random 50-character string for the Django Secret Key
resource "random_password" "django_secret" {
  length  = 50
  special = true
}

# Lock the DB Password into AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name                    = "${var.environment}/db/password"
  recovery_window_in_days = 0 # Forces immediate deletion if we destroy the environment
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

# Lock the Django Secret Key into AWS Secrets Manager
resource "aws_secretsmanager_secret" "django_secret" {
  name                    = "${var.environment}/django/secret_key"
  recovery_window_in_days = 0
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "django_secret" {
  secret_id     = aws_secretsmanager_secret.django_secret.id
  secret_string = random_password.django_secret.result
}

# ==========================================
# 3. PostgreSQL Database (RDS)
# ==========================================
resource "aws_db_instance" "main" {
  identifier             = local.db_identifier
  engine                 = "postgres"
  engine_version         = "16" # Or your preferred Postgres version
  instance_class         = "db.t4g.micro" # Cheap, ARM-based instance for Dev
  allocated_storage      = 20
  storage_type           = "gp3"
  apply_immediately      = true
  
  username               = "dbadmin"
  password               = random_password.db_password.result
  
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [var.rds_sg_id]
 
  multi_az               = var.environment == "prod" ? true : false
 
  # if the environment is "prod", skip_final_snapshot is FALSE to save the data
  # otherwise, for dev/stage, it is TRUE to delete the data
  skip_final_snapshot    = var.environment == "prod" ? false : true

  # Provide a name for the final snapshot if we are backing it up
  final_snapshot_identifier = var.environment == "prod" ? "${local.db_identifier}-final-snapshot" : null
  publicly_accessible    = false

  tags = merge(var.tags, { Name = local.db_identifier })
}

# ==========================================
# 4. ElastiCache (Valkey/Redis)
# ==========================================
resource "aws_elasticache_replication_group" "main" {
  replication_group_id       = "${var.environment}-valkey"
  description                = "Valkey replication group for ${var.environment}"
  engine                     = "valkey"
  engine_version             = "7.2" # Or whichever Valkey version you are targeting
  node_type                  = "cache.t4g.micro" # Example instance type
  subnet_group_name          = aws_elasticache_subnet_group.cache_subnets.name
  
  security_group_ids         = [var.cache_sg_id]

  # Even if you only want 1 node, this API is required for Valkey
  num_cache_clusters         = 1 
}

resource "aws_elasticache_subnet_group" "cache_subnets" {
  name       = "${var.environment}-cache-subnets"
  subnet_ids = var.private_subnets
}
