# 1. IAM Role so S3 can replicate data
resource "aws_iam_role" "replication" {
  name = "s3-replication-role-arun"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": { "Service": "s3.amazonaws.com" },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

# (Note: You would also attach a policy to this role giving it S3 permissions)

# 2. Source Bucket (US)
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645"
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration { status = "Enabled" }
}

# 3. Destination Bucket (Ireland)
resource "aws_s3_bucket" "destination" {
  provider = aws.ireland
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration { status = "Enabled" }
}

# 4. The Replication Rule (The actual 'Sync' Engine)
resource "aws_s3_bucket_replication_configuration" "replication" {
  role   = aws_iam_role.replication.arn
  bucket = aws_s3_bucket.source.id

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.destination.arn
      storage_class = "STANDARD"
    }
  }
}