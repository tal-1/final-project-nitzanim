terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket" # Must match the bucket name you created above
    key            = "global/ecr/terraform.tfstate"   # Where inside the bucket to save the ECR state
    region         = "us-east-1"
    dynamodb_table = "st-status-page-tf-locks"        # Must match the DynamoDB table name
    encrypt        = true
  }
}
