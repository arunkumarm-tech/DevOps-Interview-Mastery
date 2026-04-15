# Phase 1: Infrastructure Foundations & Troubleshooting Mastery

This document outlines the core scenarios completed in Phase 1 of the DevSecOps/SRE mastery path. It details the challenges faced, the underlying architectural concepts, and the step-by-step CLI solutions used to resolve them.

## 1. Scenario 1: Terraform State Drift
**The Concept:** Managing discrepancies between the declarative Terraform code and manual (imperative) changes made directly in the cloud console.
**The Struggle:** Someone manually modified a cloud resource, causing the local state to fall out of sync with actual cloud reality, potentially leading to accidental resource destruction on the next apply.
**The Solution:**
1. Identified the drift by running a speculative execution plan.
2. Re-synchronized the local state with the cloud provider without modifying infrastructure.
3. Updated the code to match the required cloud state or reverted the manual change via Terraform.
**Key Commands:**
- `terraform plan` (Identified the drift)
- `terraform refresh` (Updated local state to match reality)

## 2. Scenario 2: Kubernetes CrashLoopBackOff
**The Concept:** Pod lifecycle management and container initialization failures.
**The Struggle:** A deployed application pod repeatedly crashed and restarted, entering the `CrashLoopBackOff` state due to misconfigurations (e.g., missing environment variables, wrong entrypoint, or failed application startup).
**The Solution:**
1. Inspected the cluster to identify failing pods.
2. Extracted the specific failure reason from the pod's event history.
3. Examined the container's standard output logs from the failed run.
4. Corrected the deployment manifest (`deployment.yaml`) and applied the fix.
**Key Commands:**
- `kubectl get pods`
- `kubectl describe pod <pod-name>` (Checked events and exit codes)
- `kubectl logs <pod-name> --previous` (Checked logs of the crashed container)
- `kubectl apply -f deployment.yaml`

## 3. Scenario 9: Kubernetes Resource Limits (OOMKilled)
**The Concept:** Node resource allocation and container memory management.
**The Struggle:** A pod was abruptly terminated by the Kubernetes node with an `OOMKilled` (Out of Memory) status because it exceeded its allocated memory limits.
**The Solution:**
1. Diagnosed the termination reason via pod descriptions.
2. Adjusted the `resources.requests` and `resources.limits` in the pod manifest to provide adequate memory overhead for the application.
**Key Commands:**
- `kubectl describe pod <pod-name>` (Identified `Reason: OOMKilled`)
- `kubectl apply -f deployment.yaml` (Applied updated memory limits)

## 4. Scenario 8: Terraform Remote State & Locking (Production Grade)
**The Concept:** Securing infrastructure state in a centralized backend (AWS S3) and preventing concurrent modification corruption (DynamoDB locking).
**The Struggles & Solutions:**

* **Struggle A: Git Push Rejected (Large Files)**
    * *Issue:* Accidentally committed the 700MB `.terraform` provider binary folder, which GitHub rejected.
    * *Solution:* Removed the cached files from Git tracking, updated the `.gitignore` to exclude `.terraform/`, and amended the commit.
    * *Commands:* `git rm -r --cached .terraform`, `git commit --amend`
* **Struggle B: Provider Version Conflicts**
    * *Issue:* `unsupported attribute "region"` error due to a mismatch between the local provider binary and the state file's expected schema version.
    * *Solution:* Upgraded the provider lock file to sync with modern AWS provider versions (~> 5.0).
    * *Command:* `terraform init -upgrade`
* **Struggle C: The "Split Identity" & Ghost Locks**
    * *Issue:* Terraform applied resources to an older, default AWS account while the browser was logged into the new environment. This led to `ResourceNotFoundException` for locks and `BucketAlreadyExists` errors due to S3's global namespace rules.
    * *Solution:* Verified the CLI identity, generated new AWS IAM access keys, reconfigured the terminal, and wiped the corrupted local `.terraform` cache. Renamed the S3 bucket using a unique identifier (account ID suffix).
    * *Commands:* - `aws sts get-caller-identity` (Identity check)
        - `aws configure` (Injected correct credentials)
        - `rm -rf .terraform && rm .terraform.lock.hcl` (Hard cache reset)
* **Struggle D: Adopting Existing Infrastructure**
    * *Issue:* Moving from local to remote state required "adopting" the newly created S3 bucket and DynamoDB table into the local state map before migration.
    * *Solution:* Used the import function to sync local state with live AWS resources, then executed the final state migration.
    * *Commands:*
        - `terraform import aws_s3_bucket.terraform_state <bucket-name>`
        - `terraform init -migrate-state`
