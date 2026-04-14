# DevOps Technical Interview: 100 Scenarios & Solutions

## [cite_start]Phase 1: Advanced DevOps & Cloud Scenarios (Questions 1–10) [cite: 1]

### [cite_start]1. Scenario: Terraform State Drift [cite: 2]
**Question:** You discover that someone manually modified an AWS Security Group rule in the Console, but your Terraform code hasn't changed. [cite_start]How do you handle this "drift," and how would you prevent it in a production environment? [cite: 3, 4]

[cite_start]**Answer:** [cite: 5]
* [cite_start]**Resolution:** I would first run `terraform plan` to identify the exact differences. [cite: 6] [cite_start]I would then perform a `terraform apply` to overwrite the manual changes and bring the infrastructure back to the state defined in the code. [cite: 7]
* [cite_start]**Prevention:** I would implement a **GitOps** workflow where manual access to the AWS Console is restricted (Least Privilege). [cite: 8] [cite_start]I would also set up a scheduled CI job (e.g., in Jenkins or GitLab CI) that runs `terraform plan --detailed-exitcode` daily to alert the team if any drift is detected. [cite: 9]

### [cite_start]2. Scenario: Kubernetes CrashLoopBackOff [cite: 10]
**Question:** A critical microservice is stuck in `CrashLoopBackOff` after a new deployment. [cite_start]Walk me through your troubleshooting steps to identify the root cause. [cite: 11, 12]

[cite_start]**Answer:** [cite: 13]
* [cite_start]**Logs:** First, I run `kubectl logs <pod-name> --previous` to see the logs from the crashed instance. [cite: 14]
* [cite_start]**Events:** I run `kubectl describe pod <pod-name>` to check for issues like failed liveness/readiness probes, OOMKills (Out of Memory), or ImagePullBackOff. [cite: 15]
* [cite_start]**Config:** I verify if required ConfigMaps or Secrets are missing or if environment variables are incorrectly set. [cite: 16]
* [cite_start]**Resources:** If it's an OOMKill, I analyze the resource limits and requests in the deployment manifest and adjust them. [cite: 17]

### [cite_start]3. Scenario: CI/CD Pipeline Security [cite: 18]
[cite_start]**Question:** How do you securely manage sensitive data like AWS Access Keys or Database passwords within a Jenkins or GitLab CI pipeline? [cite: 19]

[cite_start]**Answer:** [cite: 20]
* [cite_start]**Avoid Hardcoding:** Never store secrets in the repository. [cite: 21]
* [cite_start]**Secret Managers:** I prefer using **AWS Secrets Manager** or **HashiCorp Vault**. [cite: 22]
* [cite_start]**IAM Roles:** The pipeline should assume an IAM Role (using OIDC for GitLab/GitHub or IAM Roles for EC2/EKS) to fetch secrets at runtime. [cite: 23]
* [cite_start]**Masking:** Ensure that "Secret Masking" is enabled in the CI tool so passwords are not printed in build logs. [cite: 24]

### [cite_start]4. Scenario: AWS Multi-Region Terraform Deployment [cite: 25]
**Question:** You need to deploy the same infrastructure across two different AWS regions (e.g., us-east-1 and us-west-2) using Terraform. [cite_start]How do you structure your code? [cite: 26, 27]

[cite_start]**Answer:** [cite: 28]
* [cite_start]**Providers:** I define two provider blocks for AWS, using an `alias` for the second region. [cite: 29]
* [cite_start]**Modules:** I write the core infrastructure (VPC, EC2, RDS) as a reusable module. [cite: 30]
* [cite_start]**Implementation:** In the root module, I call the same module twice, passing the respective provider alias and region-specific variables (like CIDR blocks) to each call. [cite: 31, 32]

---

## [cite_start]Phase 2: Architecture & Advanced Scaling (Questions 11–20) [cite: 75]

### [cite_start]11. Scenario: Terraform Workspace vs. Modules [cite: 76]
[cite_start]**Question:** In a large-scale project, when would you choose to use Terraform Workspaces versus a Directory-based module structure for managing different environments? [cite: 77]

[cite_start]**Answer:** [cite: 78]
* [cite_start]**Workspaces:** Best for managing the *same* infrastructure across environments with minimal differences; useful for quick testing but risky for production. [cite: 79, 80]
* [cite_start]**Directory-based (Modules):** The industry standard for production. [cite: 81] [cite_start]Each environment has its own folder (e.g., `environments/prod/`) and its own backend configuration for better isolation and reduced blast radius. [cite: 82, 83]

### [cite_start]16. Scenario: Kubernetes Scaling (HPA vs. Cluster Autoscaler) [cite: 113]
[cite_start]**Question:** What is the difference between the Horizontal Pod Autoscaler (HPA) and the Cluster Autoscaler, and how do they work together? [cite: 114]

[cite_start]**Answer:** [cite: 115]
* [cite_start]**HPA:** Scales the **number of pods** based on metrics like CPU or Memory usage. [cite: 116, 117]
* [cite_start]**Cluster Autoscaler:** Scales the **number of nodes** (EC2 instances). [cite: 118]
* [cite_start]**Interaction:** When HPA creates more pods than the existing nodes can handle, those pods stay "Pending." [cite: 119] [cite_start]The Cluster Autoscaler detects this and triggers the AWS Auto Scaling Group to add a new node. [cite: 120]
