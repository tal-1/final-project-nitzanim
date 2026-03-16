provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "django_app" {
  name                 = "st-status-page-app" # The name of your Docker repo
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "aws_ecr_lifecycle_policy" "django_app_cleanup" {
  repository = aws_ecr_repository.django_app.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Protect Production/Stage SemVer tags (v*)"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber   = 9999 # Effectively keeps up to 9999 release images indefinitely
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete temporary Dev images (Commit IDs) and untagged images older than 14 days"
        selection = {
          tagStatus   = "any"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 14
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

resource "aws_ecr_pull_through_cache_rule" "ecr_public_cache" {
  ecr_repository_prefix = "ecr-public"
  upstream_registry_url = "public.ecr.aws"
}
