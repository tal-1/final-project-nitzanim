terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket"
    key            = "global/github_oidc/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "st-status-page-tf-locks"
    encrypt        = true
  }
}
