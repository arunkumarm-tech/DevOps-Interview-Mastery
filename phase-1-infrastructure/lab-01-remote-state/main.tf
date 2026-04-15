terraform {
  backend "s3" {
    bucket         = "arun-kumar-devops-state-2026" # Use the exact name from your code
    key            = "phase-1/terraform.tfstate"
    region         = "us-east-1"                   # Change this if you used a different region
    dynamodb_table = "terraform-state-locking"
    encrypt        = true
  }
}

# 1. The S3 Bucket for State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "arun-kumar-devops-state-2026" # Must be unique globally
  
  lifecycle {
    prevent_destroy = true # Safety first!
  }
}

# 2. Enable Versioning so we can roll back state
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. The DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}
