# 3. Create Source Bucket (US)
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645" # Must be unique globally
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# 4. Create Destination Bucket (Ireland)
resource "aws_s3_bucket" "destination" {
  provider = aws.ireland # Directs this resource to Ireland
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}