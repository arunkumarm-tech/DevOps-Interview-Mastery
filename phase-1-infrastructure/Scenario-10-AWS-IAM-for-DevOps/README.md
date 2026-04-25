# Scenario-10-AWS-IAM-for-DevOps status: completed

# Scenario 10: Implementing Least Privilege with AWS IAM Roles & Instance Profiles

## Objective
To eliminate the use of static AWS Access Keys/Secret Keys and implement a "Zero-Key" architecture. This lab demonstrates how to grant an EC2 instance secure, temporary access to an S3 bucket using IAM Roles and Instance Profiles, following the **Principle of Least Privilege**.

## Architecture
1. **S3 Bucket:** Private bucket for production logs.
2. **IAM Role:** A role with a Trust Policy allowing the `ec2.amazonaws.com` service to assume it.
3. **IAM Policy:** A granular policy allowing `ListBucket` and `PutObject`, but strictly omitting `DeleteObject`.
4. **EC2 Instance:** A t3.micro instance utilizing the IAM Instance Profile.

---

## Phase 1: Infrastructure as Code (Terraform)
The infrastructure was provisioned using Terraform to ensure idempotency and version control.



```hcl
# Key highlights of the implementation:
resource "aws_iam_role" "ec2_log_role" {
  name = "EC2LogUploaderRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Least Privilege Policy: No Delete permissions granted.
resource "aws_iam_policy" "s3_upload_policy" {
  name = "S3UploadOnlyPolicy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::arun-production-logs-2026"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["arn:aws:s3:::arun-production-logs-2026/*"]
      }
    ]
  })
}

### **Phase 2: Troubleshooting & Lessons Learned**

| Step | Issue Encountered | Root Cause Analysis | Resolution / Specialist Insight |
| :--- | :--- | :--- | :--- |
| **01** | **SSH Connection Failed** | The EC2 instance was launched without a custom Security Group, defaulting to a "Deny All" ingress policy for Port 22. | **Resolution:** Updated Terraform to include an `aws_security_group` resource with an ingress rule for Port 22. <br>**Insight:** Always verify Egress rules to ensure the instance can reach the S3 API on Port 443. |
| **02** | **Incorrect IAM Context** | `aws sts get-caller-identity` showed `arn:aws:iam::...:root` instead of the expected Role. | **Resolution:** Recognized that the command was being executed on the local MacBook Air (using local credentials) rather than inside the EC2 environment. <br>**Insight:** IAM Instance Profiles must be verified from the metadata-aware environment of the instance itself. |
| **03** | **File Not Found (S3 CP)** | `The user-provided path test.txt does not exist.` | **Resolution:** Realized that as a stateless instance, the test file created on the MacBook was not present on the EC2. <br>**Insight:** Used `echo` to create a fresh test file locally on the EC2 before testing the S3 upload capability. |
| **04** | **Access Denied (Success)** | Attempting to delete a file resulted in an explicit `AccessDenied` error from the S3 API. | **Result:** **Confirmed Success.** This confirmed that the "Least Privilege" policy was correctly ignoring the `DeleteObject` action. |




Phase 2: Troubleshooting & Lessons Learned
Observation 1: Network Connectivity (SSH Failure)
Issue: Initial attempt to connect to the EC2 instance via browser-based SSH failed.
Cause: The default Security Group did not allow inbound traffic on Port 22 (SSH).
Mitigation: Updated Terraform to include a Security Group resource allowing ingress on Port 22 and egress on Port 443 (for S3 API calls).

Observation 2: Context Confusion (Local vs. Remote)
Issue: Running aws sts get-caller-identity on the local MacBook Air returned the root/admin identity.
Lesson: To verify an Instance Profile, commands must be executed inside the EC2 environment to utilize the metadata service credentials.

Phase 3: Final Verification (The Success)
1. Identity Verification
Inside the EC2, the identity was confirmed as the Assumed Role, proving no static keys were in use.

Bash
$ aws sts get-caller-identity
{
    "Arn": "arn:aws:sts::160827082645:assumed-role/EC2LogUploaderRole/i-0b30dc491499b1ae0"
}
2. Functional Test (Upload)
Successfully uploaded a log file to the production bucket.

Bash
$ aws s3 cp lab-test.txt s3://arun-production-logs-2026/
upload: ./lab-test.txt to s3://arun-production-logs-2026/lab-test.txt
3. Security Test (Least Privilege Enforcement)
Attempting to delete the file resulted in an AccessDenied error, confirming the policy effectively prevented unauthorized actions.

Bash
$ aws s3 rm s3://arun-production-logs-2026/lab-test.txt
delete failed: ... An error occurred (AccessDenied) when calling the DeleteObject operation.
Conclusion
This scenario confirms that by using IAM Instance Profiles, we can significantly reduce the attack surface of our cloud infrastructure while maintaining high operational efficiency.
