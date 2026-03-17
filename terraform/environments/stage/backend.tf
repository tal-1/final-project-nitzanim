terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket"
    key            = "environments/stage/terraform.tfstate"
    encrypt        = true
  }
}
