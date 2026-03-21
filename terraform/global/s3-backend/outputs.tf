output "state_bucket_name" {
  description = "The name of the S3 bucket storing Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB table managing state locks"
  value = [for table in aws_dynamodb_table.terraform_locks : table.name]
}
