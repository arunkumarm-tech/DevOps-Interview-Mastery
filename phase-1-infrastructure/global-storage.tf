# 1. IAM Role: The "Identity" for S3 to use
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

# 2. IAM Policy: The "Permissions" (Read from US, Write to EU)
resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy-arun"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["s3:GetReplicationConfiguration", "s3:ListBucket"],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::arun-data-master-us-082645"]
    },
    {
      "Action": ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl"],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::arun-data-master-us-082645/*"]
    },
    {
      "Action": ["s3:ReplicateObject", "s3:ReplicateDelete"],
      "Effect": "Allow",
      "Resource": ["arn:aws:s3:::arun-data-backup-eu-082645/*"]
    }
  ]
}
POLICY
}

# 3. Attach Policy to Role
resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# 4. Source Bucket (US)
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645"
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration { status = "Enabled" }
}

# 5. Destination Bucket (Ireland)
resource "aws_s3_bucket" "destination" {
  provider = aws.ireland
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration { status = "Enabled" }
}

# 6. Replication Rule (The Sync Engine)
resource "aws_s3_bucket_replication_configuration" "replication" {
  depends_on = [aws_s3_bucket_versioning.source_v, aws_s3_bucket_versioning.dest_v]

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