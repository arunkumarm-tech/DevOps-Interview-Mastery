terraform {
  # Keep this block commented out for now!
   backend "s3" {
     bucket         = "arun-mx-state-082645" # NEW NAME
     key            = "phase-1/terraform.tfstate"
     region         = "us-east-1"
     dynamodb_table = "terraform-state-locking-v2"
     encrypt        = true
   }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 1. The S3 Bucket for State
resource "aws_s3_bucket" "terraform_state" {
  bucket = "arun-mx-state-082645" # NEW NAME HERE TOO
  
  lifecycle {
    prevent_destroy = true 
  }
}

# 2. Enable Versioning
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 3. The DynamoDB Table for Locking
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-state-locking-v2" # Changed name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}