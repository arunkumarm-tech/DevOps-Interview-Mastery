# Scenario 5: AWS Multi-Region S3 Storage & Automated Replication

## 🎯 1. The Senior Narrative (Interview Response)
**Interviewer Question:** *"How do you design and implement a geographically redundant storage system that survives a total AWS regional outage?"*

**My Professional Answer:**
"I implement **S3 Cross-Region Replication (CRR)** using a 'Hub-and-Spoke' architecture. This involves a **Centralized Provider Strategy** where all regional configurations are managed in a single `providers.tf` file using Aliases. The solution requires three pillars: **Versioning** for data integrity, a dedicated **IAM Service Role** with granular policies for cross-region data movement, and an **Automated Replication Engine**. This setup ensures that data uploaded to our primary US region is physically and asynchronously replicated to our European backup region, meeting high-availability and disaster recovery requirements."

---

## 🛠️ 2. Step-by-Step Practical Execution

### Phase A: Centralizing the "Global Brain"
To manage multiple regions without conflicts, we move all authentication logic to one file.
**File:** `providers.tf`
```hcl
# Default Provider (Primary Region)
provider "aws" {
  region = "us-east-1"
}

# Aliased Provider (Secondary Region)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}


Phase B: Building the Replication Engine
This file handles the security, the physical storage, and the sync rules.
File: global-storage.tf


# 1. IAM Permissions (Giving S3 'hands' to move data)
resource "aws_iam_role" "replication" {
  name = "s3-replication-role-arun"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Principal = { Service = "s3.amazonaws.com" }
      Effect = "Allow"
    }]
  })
}

resource "aws_iam_policy" "replication" {
  name = "s3-replication-policy-arun"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = ["s3:GetReplicationConfiguration", "s3:ListBucket"]
        Effect = "Allow"
        Resource = ["arn:aws:s3:::arun-data-master-us-082645"]
      },
      {
        Action = ["s3:GetObjectVersionForReplication", "s3:GetObjectVersionAcl"]
        Effect = "Allow"
        Resource = ["arn:aws:s3:::arun-data-master-us-082645/*"]
      },
      {
        Action = ["s3:ReplicateObject", "s3:ReplicateDelete"]
        Effect = "Allow"
        Resource = ["arn:aws:s3:::arun-data-backup-eu-082645/*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication" {
  role       = aws_iam_role.replication.name
  policy_arn = aws_iam_policy.replication.arn
}

# 2. Regional S3 Buckets
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645"
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket" "destination" {
  provider = aws.ireland
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration { status = "Enabled" }
}

# 3. Automation Logic (Replication Configuration)
resource "aws_s3_bucket_replication_configuration" "replication" {
  # Fix for Race Condition: Wait for Versioning to be active
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


⚠️ 3. Real-World Challenges & Troubleshooting
During the implementation, we encountered and resolved three professional-grade issues:

Issue 1: Duplicate Provider Error

Symptoms: Error: Duplicate provider configuration in multi-region.tf and global-storage.tf.

Cause: Multiple files defining the same AWS provider without aliases.

Solution: Consolidated all provider blocks into providers.tf and removed redundant blocks from all other files.

Issue 2: The Versioning Race Condition

Symptoms: InvalidRequest: Destination bucket must have versioning enabled.

Cause: Terraform tried to create replication before the AWS API had finished enabling versioning in the Ireland region.

Solution: Added an explicit depends_on block to the replication resource to force the correct execution order.

Issue 3: The "Ghost Sync" (Permission Denial)

Symptoms: Buckets existed in both regions, but data would not move.

Cause: The IAM role was created but lacked the IAM Policy Attachment needed to physically "Read" and "Write" objects across regions.

Solution: Added a specific IAM Policy and Attachment to grant S3 the necessary cross-region permissions.

🧪 4. Validation & Proof of Success
CLI Atlantic Data Test
Local Creation: echo "Arun's Global Test" > validation.txt

Upload to US: aws s3 cp validation.txt s3://arun-data-master-us-082645/

Verify in EU: aws s3 ls s3://arun-data-backup-eu-082645/

Result: The file appeared in the Ireland bucket in < 60 seconds, proving the automation works.

Console Geographical Check
Properties Tab: Selecting the arun-data-backup-eu-082645 bucket confirms the physical region as Europe (Ireland) eu-west-1, independent of the master bucket.

💡 5. Master Command Glossary
Provider Alias: Enables a single Terraform codebase to manage resources in different geographical regions.

depends_on: A meta-argument used to solve timing dependencies (race conditions) between API calls.

JSONENCODE: A modern Terraform function used to format IAM policies clearly within the HCL code.

dquote>: A terminal prompt indicating an unclosed quote; resolved by using Ctrl+C and running commands line-by-line.

