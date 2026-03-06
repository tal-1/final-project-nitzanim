locals {
environment = var.environment
project = "ST-status-page"
common_tags = {
	"CreatedBy" = "ST-Project"
	"Environment" = local.environment
	"ManagedBy" = "ST-status-page"
	}
}
