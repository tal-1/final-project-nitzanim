provider "aws" {
  region = "us-east-1"
}

# 1. S3 Bucket for Terraform State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "st-status-page-tf-state-bucket" 
}

# Enable versioning so you can roll back if your state file gets corrupted
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Secure the bucket (Block all public access)
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 2. DynamoDB Table for State Locking
resource "aws_dynamodb_table" "terraform_locks" {
  for_each     = toset(["dev", "stage", "prod"])
  name         = "${each.key}-st-status-page-tf-locks"
  billing_mode = "PAY_PER_REQUEST" # Free tier friendly
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
