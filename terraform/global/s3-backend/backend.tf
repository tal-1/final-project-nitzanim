# ==============================================================================
# THE BOOTSTRAP PARADOX
# ==============================================================================
# 1. When you FIRST run this code, this entire block MUST remain commented out.
#    Terraform will create the bucket and save the state locally on your laptop.
# 2. AFTER the bucket is created, remove the /* and */ comments.
# 3. Run `terraform init` again. Terraform will ask: "Do you want to copy your 
#    local state into the new S3 bucket?" You say "yes".
# ==============================================================================

/*
terraform {
  backend "s3" {
    bucket         = "st-status-page-tf-state-bucket"  # Change to your actual bucket name
    key            = "global/s3-backend/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "st-status-page-tf-locks"         # Change to your actual table name
    encrypt        = true
  }
}
*/
