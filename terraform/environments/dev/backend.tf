terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket"
    key            = "environments/dev/terraform.tfstate"
    encrypt        = true
  }
}
