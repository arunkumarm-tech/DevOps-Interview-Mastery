# Scenario 1: Terraform State Drift

### The Problem
You discover that someone manually modified an AWS Security Group rule in the Console, but your Terraform code hasn't changed.

### The Solution
* **Identify:** Run `terraform plan`. This compares the "Real World" (AWS) with your "State File."
* **Remediate:** Run `terraform apply`. This will overwrite the manual changes and bring the infrastructure back to what is defined in your code.
* **Prevention:** Implement a **GitOps** workflow. Restrict manual access to the AWS Console (Least Privilege) and set up a scheduled CI job to run `terraform plan` daily to alert the team of any drift.