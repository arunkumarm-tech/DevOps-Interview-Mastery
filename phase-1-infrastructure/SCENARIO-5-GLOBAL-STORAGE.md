Scenario 5: Updated Master Source (The Clean Version)
Since we changed the architecture to use a providers.tf file, I have updated SCENARIO-5-GLOBAL-STORAGE.md

# Scenario 5: Multi-Region S3 Storage (Disaster Recovery)

## 🎯 1. The Interviewer Response
**Question:** *"If a whole AWS region goes down, how do you ensure our data stays safe? How would you set up Cross-Region Replication in Terraform?"*

**My Professional Answer:**
"I follow a **Centralized Provider Strategy**. By defining global regions in a dedicated `providers.tf` file using Aliases, I can manage infrastructure across continents from a single codebase. For S3, I provision a 'Source' bucket in the US and a 'Destination' bucket in Ireland. By enabling **Versioning** on both, I create the foundation for S3 Cross-Region Replication (CRR), ensuring that our data is geographically redundant and durable even during a total regional outage."

---

## 🛠️ 2. Step-by-Step Practical Execution

### Phase A: Centralizing Providers (Best Practice)
To avoid 'Duplicate Provider' errors, we moved all regional configurations to one file.

**File:** `providers.tf`
```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

Phase B: Global Storage Configuration
File: global-storage.tf

# Create Source Bucket (US)
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645" 
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create Destination Bucket (Ireland)
resource "aws_s3_bucket" "destination" {
  provider = aws.ireland # Targets the Alias in providers.tf
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}

This is a classic "Senior Engineer" mistake—and it's actually a great learning moment.

In Terraform, all .tf files in the same folder are merged together into one giant configuration. Because you already created the provider blocks in multi-region.tf, you cannot define them again in global-storage.tf. Terraform sees two "Default" providers and gets confused.

The Fix: The "Centralized Providers" Strategy
To fix this and prevent it from happening as we move toward 100 scenarios, we will move all your provider configurations into one single file called providers.tf. This is the professional way to manage a large project.

Step 1: Create a single Provider file
In your phase-1-infrastructure folder, create a new file:

Bash
nano providers.tf
Step 2: Paste the global provider logic here
Terraform
# The Default Provider (US-East-1)
provider "aws" {
  region = "us-east-1"
}

# The Ireland Alias
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}
Step 3: Clean up your other files
Now, you need to remove the provider "aws" { ... } blocks from your other files so they don't conflict.

Open multi-region.tf: Delete the first 11 lines (the provider blocks). Keep only the resource blocks.

Open global-storage.tf: Delete the first 11 lines (the provider blocks). Keep only the resource blocks.

Step 4: Re-Initialize
Now that the duplicates are gone, run the initialization again:

Bash
terraform init
Scenario 5: Updated Master Source (The Clean Version)
Since we changed the architecture to use a providers.tf file, I have updated your documentation. Copy this into your SCENARIO-5-GLOBAL-STORAGE.md.

Markdown
# Scenario 5: Multi-Region S3 Storage (Disaster Recovery)

## 🎯 1. The Interviewer Response
**Question:** *"If a whole AWS region goes down, how do you ensure our data stays safe? How would you set up Cross-Region Replication in Terraform?"*

**My Professional Answer:**
"I follow a **Centralized Provider Strategy**. By defining global regions in a dedicated `providers.tf` file using Aliases, I can manage infrastructure across continents from a single codebase. For S3, I provision a 'Source' bucket in the US and a 'Destination' bucket in Ireland. By enabling **Versioning** on both, I create the foundation for S3 Cross-Region Replication (CRR), ensuring that our data is geographically redundant and durable even during a total regional outage."

---

## 🛠️ 2. Step-by-Step Practical Execution

### Phase A: Centralizing Providers (Best Practice)
To avoid 'Duplicate Provider' errors, we moved all regional configurations to one file.

**File:** `providers.tf`
```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}
Phase B: Global Storage Configuration
File: global-storage.tf

Terraform
# Create Source Bucket (US)
resource "aws_s3_bucket" "source" {
  bucket = "arun-data-master-us-082645" 
}

resource "aws_s3_bucket_versioning" "source_v" {
  bucket = aws_s3_bucket.source.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Create Destination Bucket (Ireland)
resource "aws_s3_bucket" "destination" {
  provider = aws.ireland # Targets the Alias in providers.tf
  bucket   = "arun-data-backup-eu-082645"
}

resource "aws_s3_bucket_versioning" "dest_v" {
  provider = aws.ireland
  bucket   = aws_s3_bucket.destination.id
  versioning_configuration {
    status = "Enabled"
  }
}
🧪 3. Validation and Testing
Method 1: The Terraform Plan
Run terraform plan.
Verification: Ensure it shows 4 resources to add (2 buckets and 2 versioning configurations).

Method 2: CLI Global List
aws s3 ls
Verification: You should see both new buckets listed globally.

💡 4. Master Command Glossary
Duplicate provider configuration : An error occurring when two files in the same folder define the same provider without different aliases.

providers.tf : A professional naming convention for a file that holds all region and authentication logic.

aws s3 ls : CLI command to list all buckets in the account across all regions.