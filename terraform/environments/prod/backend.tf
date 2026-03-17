terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket"
    key            = "environments/prod/terraform.tfstate"
    encrypt        = true
  }
}
