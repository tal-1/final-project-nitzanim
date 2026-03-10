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
