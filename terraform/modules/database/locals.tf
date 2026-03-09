locals {
  db_identifier    = "${var.environment}-postgres"
  cache_cluster_id = "${var.environment}-valkey"
  subnet_group_name = "${var.environment}-db-subnet-group"
}
