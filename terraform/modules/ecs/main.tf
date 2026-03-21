# ==========================================
# 1. ECS Cluster & CloudWatch Logs
# ==========================================
resource "aws_ecs_cluster" "main" {
  name = local.cluster_name
  tags = merge(var.tags, { Name = local.cluster_name })
}

resource "aws_cloudwatch_log_group" "ecs_logs" {
  name              = "/ecs/${local.task_family}"
  retention_in_days = 30
  tags              = var.tags
}

# ==========================================
# 2. IAM Roles (Strict Least-Privilege)
# ==========================================

# --- Task Role (The Application) ---
# As you requested: Zero permissions to Secrets Manager. Just basic ECS trust.
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.environment}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

# --- Task Execution Role (The Bootstrapper) ---
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.environment}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
  tags = var.tags
}

# Attach standard AWS permissions (to pull images from ECR and send logs)
resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach STRICT Secrets Manager permissions (Only exact ARNs!)
resource "aws_iam_role_policy" "ecs_execution_secrets_policy" {
  name = "${var.environment}-ecs-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["secretsmanager:GetSecretValue"],
      Resource = [
        var.db_password_secret_arn,
        var.django_secret_key_arn
      ]
    }]
  })
}

# ==========================================
# 3. Task Definition (The Container Blueprint)
# ==========================================
resource "aws_ecs_task_definition" "app" {
  family                   = local.task_family
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256 # 0.25 vCPU (Minimum)
  memory                   = 512 # 0.5 GB RAM (Minimum)
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "django-app"
    image     = var.container_image
    essential = true
    
    portMappings = [{
      containerPort = 8000
      hostPort      = 8000
      protocol      = "tcp"
    }]

    # Non-sensitive environment variables
    environment = [
      { name = "DB_HOST", value = var.db_endpoint },
      { name = "DB_NAME", value = "statuspage" },
      { name = "DB_USER", value = "dbadmin" },
      { name = "DB_PORT", value = "5432" },
      { name = "REDIS_HOST", value = var.cache_endpoint },
      { name = "REDIS_PORT", value = "6379" }
    ]

    # Sensitive secrets injected securely!
    secrets = [
      { name = "DB_PASSWORD", valueFrom = var.db_password_secret_arn },
      { name = "DJANGO_SECRET_KEY", valueFrom = var.django_secret_key_arn }
    ]

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = aws_cloudwatch_log_group.ecs_logs.name
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
  
  tags = var.tags
}

# ==========================================
# 4. ECS Service (The Manager)
# ==========================================
resource "aws_ecs_service" "app" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 2 # Run 2 containers for high availability
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [var.ecs_security_group]
    assign_public_ip = false # Security best practice: containers stay totally private
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = "django-app"
    container_port   = 8000
  }

  tags = var.tags
  # once creating the service the very first time, TF completely ignores the task_definition version. Because TF is now "blind" to the task definition, GitHub Actions pipeline is free to update the task definition to v1.2.3, v1.2.4, etc., and TF will never try to interfere or roll it back during infrastructure syncs.
  lifecycle {
    ignore_changes = [task_definition]
  }
}
