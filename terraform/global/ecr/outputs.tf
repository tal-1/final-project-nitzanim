output "ecr_repository_url" {
  description = "The URL of the ECR repository to push Docker images to"
  value       = aws_ecr_repository.django_app.repository_url
}
