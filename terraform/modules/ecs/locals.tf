locals {
  cluster_name = "${var.environment}-ecs-cluster"
  service_name = "${var.environment}-django-service"
  task_family  = "${var.environment}-django-task"
}
