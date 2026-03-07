terraform {
  backend "s3" {
    bucket         = "ST-tfstate-files"
    key            = "environments/prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    # prevents two people or pipelines from making changes at the exact same time
    dynamodb_table = "terraform-state-locks"
  }
}
