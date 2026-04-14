Phase 1: Advanced DevOps & Cloud Scenarios
(Questions 1–10)
1. Scenario: Terraform State Drift
Question: You discover that someone manually modified an AWS Security Group rule in the
Console, but your Terraform code hasn't changed. How do you handle this "drift," and how
would you prevent it in a production environment?
Answer:
● Resolution: I would first run terraform plan to identify the exact differences. I would
then perform a terraform apply to overwrite the manual changes and bring the
infrastructure back to the state defined in the code.
● Prevention: I would implement a GitOps workflow where manual access to the AWS
Console is restricted (Least Privilege). I would also set up a scheduled CI job (e.g., in
Jenkins or GitLab CI) that runs terraform plan --detailed-exitcode daily to
alert the team if any drift is detected.
2. Scenario: Kubernetes CrashLoopBackOff
Question: A critical microservice is stuck in CrashLoopBackOff after a new deployment. Walk
me through your troubleshooting steps to identify the root cause.
Answer:
1. Logs: First, I run kubectl logs <pod-name> --previous to see the logs from the
crashed instance.
2. Events: I run kubectl describe pod <pod-name> to check for issues like failed
liveness/readiness probes, OOMKills (Out of Memory), or ImagePullBackOff.
3. Config: I verify if the required ConfigMaps or Secrets are missing or if the environment
variables are incorrectly set.
4. Resources: If it's an OOMKill, I analyze the resource limits and requests in the
deployment manifest and adjust them based on the application's needs.
3. Scenario: CI/CD Pipeline Security
Question: How do you securely manage sensitive data like AWS Access Keys or Database
passwords within a Jenkins or GitLab CI pipeline?
Answer:
● Avoid Hardcoding: Never store secrets in the repository.
● Secret Managers: I prefer using AWS Secrets Manager or HashiCorp Vault. The
pipeline should assume an IAM Role (using OIDC for GitLab/GitHub or IAM Roles for
EC2/EKS if Jenkins is on AWS) to fetch secrets at runtime.
● Masking: Ensure that "Secret Masking" is enabled in the CI tool so passwords are not
printed in the build logs.
4. Scenario: AWS Multi-Region Terraform Deployment
Question: You need to deploy the same infrastructure across two different AWS regions (e.g.,
us-east-1 and us-west-2) using Terraform. How do you structure your code?
Answer:
● Providers: I define two provider blocks for AWS, using alias for the second region.
● Modules: I write the core infrastructure (VPC, EC2, RDS) as a reusable module.
● Implementation: In the root module, I call the same module twice, passing the
respective provider alias and region-specific variables (like CIDR blocks) to each call.
This ensures consistency while allowing for regional variations.
5. Scenario: Optimizing Docker Image Size
Question: A developer complains that their Docker build takes 10 minutes and the image is
2GB. How do you optimize this for a CI/CD pipeline?
Answer:
● Multi-Stage Builds: Use a build stage to compile the code and a final, minimal
production stage (using alpine or distroless images) to run the binary.
● Layer Optimization: Combine RUN commands (e.g., apt-get update && apt-get
install...) and clean up cache files in the same layer.
● .dockerignore: Use a .dockerignore file to prevent heavy directories like .git or
node_modules from being copied into the build context.
6. Scenario: High Availability in EKS
Question: How do you ensure that your Kubernetes application on AWS EKS remains available
even if an entire Availability Zone (AZ) goes down?
Answer:
● VPC Design: Ensure the EKS cluster is deployed across at least three private subnets
in three different AZs.
● Node Groups: Use Managed Node Groups that span multiple AZs.
● Pod Topology: Use topologySpreadConstraints or podAntiAffinity in the
deployment manifest to force Kubernetes to distribute pods across different nodes and
zones, preventing all replicas from sitting in one failing AZ.
7. Scenario: Blue/Green Deployment with Route53
Question: Describe how you would perform a Blue/Green deployment for a web application
using AWS Route53 and ALB.
Answer:
1. Green Environment: Use Terraform to spin up a completely new "Green" environment
(new Auto Scaling Group and Target Group) with the new code.
2. Testing: Test the Green environment using its internal ALB DNS.
3. Cutover: Use Route53 Weighted Routing. Initially, send 100% of traffic to the "Blue"
ALB. Gradually shift weight (e.g., 90/10, then 50/50) to the Green ALB.
4. Rollback: If errors spike, immediately set the Blue weight back to 100%. If successful,
decommission the Blue environment.
8. Scenario: Terraform State Locking
Question: Why is a terraform.tfstate file stored locally dangerous in a team environment,
and how do you solve it in AWS?
Answer:
● Risk: Local state leads to "State Corruption" if two engineers run apply at the same
time. It also risks losing the file if a laptop crashes.
● Solution: Use a Remote Backend. In AWS, I store the state file in an S3 Bucket (with
versioning enabled) and use a DynamoDB Table for state locking. This ensures that
only one person/process can modify the infrastructure at a time.
9. Scenario: Kubernetes Resource Limits
Question: One of your nodes in the Kubernetes cluster is under "Disk Pressure" or "Memory
Pressure." How does Kubernetes respond, and how do you prevent this?
Answer:
● Response: The Kubelet will start evicting pods (starting with BestEffort pods) to reclaim
resources.
● Prevention: I strictly enforce requests and limits for CPU and Memory in every
deployment. I also implement ResourceQuotas at the namespace level and use a
Horizontal Pod Autoscaler (HPA) to scale pods based on actual usage rather than
letting one pod consume the entire node.
10. Scenario: AWS IAM for DevOps
Question: A Jenkins server running on an EC2 instance needs to upload build artifacts to an S3
bucket. What is the most secure way to grant this permission?
Answer:
● IAM Roles: I would create an IAM Role with a policy that allows s3:PutObject only
on that specific bucket.
● Instance Profile: I would attach this IAM Role to the EC2 instance as an Instance
Profile.
● Security: This is more secure than using Access Keys because the credentials are
automatically rotated and never stored on the server's disk.
Phase 2: Architecture & Advanced Scaling (Questions
11–20)
11. Scenario: Terraform Workspace vs. Modules
Question: In a large-scale project, when would you choose to use Terraform Workspaces
versus a Directory-based module structure for managing different environments (Dev, QA,
Prod)?
Answer:
● Workspaces: Best for managing the same infrastructure across environments with
minimal differences. It’s useful for quick testing, but since it uses the same backend
configuration, it can be risky for production.
● Directory-based (Modules): This is the industry standard for production. Each
environment has its own folder (e.g., environments/prod/) and its own backend
configuration. This provides better isolation, allows for different versions of modules in
different environments, and reduces the "blast radius" if a state file is corrupted.
12. Scenario: Kubernetes Networking (Ingress vs. LoadBalancer)
Question: Your cluster has 50 microservices. Would you create an AWS Load Balancer for
each service? Why or why not?
Answer:
● No: Creating 50 ALBs would be extremely expensive and difficult to manage.
● Solution: I would use a Kubernetes Ingress Controller (like NGINX or the AWS Load
Balancer Controller). I would deploy one (or two) ALBs that act as the entry point. Then, I
define Ingress Resources with host-based or path-based routing rules (e.g.,
api.example.com/users vs api.example.com/orders) to route traffic to the
appropriate internal ClusterIP services.
13. Scenario: AWS Lambda Networking
Question: A Lambda function needs to access an RDS database inside a private subnet. What
configuration is required, and what is a common pitfall?
Answer:
● Configuration: The Lambda must be configured to run within the VPC. You need to
provide the private Subnet IDs and a Security Group that allows outbound traffic to the
RDS port.
● Pitfall: A common issue is that a Lambda in a VPC loses access to the public internet
unless there is a NAT Gateway in the VPC. If the Lambda needs to call an external API
while talking to the DB, the subnet it’s in must have a route to a NAT Gateway.
14. Scenario: Canary Deployments in CI/CD
Question: How would you implement a Canary Deployment for a Kubernetes application using
a CI/CD pipeline?
Answer:
1. Preparation: Deploy a small percentage (e.g., 5%) of the new version pods alongside
the old version.
2. Traffic Split: Use a Service Mesh like Istio or an Ingress Controller to route 5% of traffic
to the new "canary" pods.
3. Monitoring: Monitor Prometheus metrics for error rates and latency on the canary pods.
4. Promotion: If metrics are healthy, the CI/CD pipeline (using a tool like Argo Rollouts or
Flux) gradually increases the traffic to 100% and terminates the old version.
15. Scenario: Docker Security Scanning
Question: How do you ensure that the Docker images being deployed to production do not
contain known vulnerabilities?
Answer:
● Shift Left: Integrate scanning into the CI pipeline using tools like Trivy, Snyk, or Aqua
Security.
● Registry Scanning: Enable Amazon ECR Basic/Enhanced Scanning, which
automatically scans images on push.
● Runtime Security: Use admission controllers in Kubernetes to block the deployment of
any image that hasn't been scanned or has "High" or "Critical" vulnerabilities.
16. Scenario: Kubernetes Scaling (HPA vs. Cluster Autoscaler)
Question: What is the difference between the Horizontal Pod Autoscaler (HPA) and the
Cluster Autoscaler, and how do they work together?
Answer:
● HPA: Scales the number of pods based on metrics like CPU or Memory usage. It
handles application-level load.
● Cluster Autoscaler: Scales the number of nodes (EC2 instances).
● Interaction: When HPA tries to create more pods but there is no more CPU/RAM
available on existing nodes, those pods stay in "Pending" state. The Cluster Autoscaler
detects these pending pods and triggers the AWS Auto Scaling Group to add a new
node.
17. Scenario: Terraform for_each vs. count
Question: Why is for_each generally preferred over count when creating multiple similar
resources (like 10 S3 buckets)?
Answer:
● Count: Uses an index (0, 1, 2). If you remove the bucket at index 0, Terraform may try to
shift all other buckets, causing unnecessary resource destruction and recreation.
● For_each: Uses a map or a set of strings (the bucket names). If you remove one item
from the map, Terraform only deletes that specific resource without affecting the others.
This makes the infrastructure much more stable during updates.
18. Scenario: AWS Networking (Transit Gateway)
Question: Your company has 10 different VPCs that all need to communicate with each other.
Would you use VPC Peering?
Answer:
● No: VPC Peering is "point-to-point" and does not support transitive routing. Managing 10
VPCs would require a complex "mesh" of 45 peering connections.
● Solution: I would use AWS Transit Gateway. It acts as a regional network hub. You
attach all 10 VPCs to the Transit Gateway, and it manages the routing between them
centrally, significantly simplifying the architecture.
19. Scenario: Kubernetes RBAC
Question: A developer needs to be able to view logs and restart pods in the "Development"
namespace but should not be able to touch "Production." How do you implement this?
Answer:
1. Namespace: Ensure "Dev" and "Prod" are separate namespaces.
2. Role: Create a Role in the "Dev" namespace with permissions for get, list, watch on
pods and create on pods/exec or deployments/patch (for restarts).
3. RoleBinding: Create a RoleBinding that links the developer's IAM user (mapped via
aws-auth ConfigMap or EKS Access Entries) to that specific Role in the "Dev"
namespace.
20. Scenario: CI/CD Rollback Strategy
Question: Your deployment to Production succeeded in the pipeline, but 10 minutes later, users
report that the "Login" button is broken. What is your immediate action and long-term fix?
Answer:
● Immediate: Perform an immediate Rollback to the last known stable version. In
Kubernetes, this is kubectl rollout undo deployment/<name>.
● Long-term: I would perform a Post-Mortem to identify why the automated tests in the
pipeline didn't catch this. I would then add a Smoke Test or an End-to-End (E2E) test
(e.g., using Cypress or Selenium) to the pipeline that specifically tests the login
functionality before the deployment is finalized.
—------------------------------------------------------------------------------------------
Phase 3: Monitoring, Storage, and Advanced IaC
(Questions 21–30)
21. Scenario: High Latency in Microservices
Question: Your application is experiencing intermittent high latency. You have CloudWatch
metrics, but they only show "Average Latency." How do you find the specific service or database
query causing the bottleneck?
Answer:
● Distributed Tracing: I would implement AWS X-Ray or an open-source alternative like
Jaeger. This allows us to track a single request as it travels through multiple
microservices, identifying exactly where the delay occurs.
● CloudWatch Logs Insights: I would use Logs Insights to run queries against
application logs to find outliers (e.g., requests taking > 2 seconds).
● Performance Insights: If the bottleneck is the database, I would check RDS
Performance Insights to see which specific SQL queries are causing "High Load" on
the CPU or Disk I/O.
22. Scenario: Stateful Applications in Kubernetes
Question: A developer wants to run a Database (like PostgreSQL) inside Kubernetes. Would
you use a Deployment or a StatefulSet? Explain why.
Answer:
● StatefulSet: I would use a StatefulSet. Unlike Deployments, StatefulSets provide:
1. Stable Network Identity: Each pod gets a fixed hostname (e.g., db-0, db-1).
2. Ordered Deployment/Scaling: Pods are created one by one, which is critical for
database clustering/replication.
3. Persistent Storage: Each pod is mapped to its own Persistent Volume (PV)
that stays with the pod even if it is deleted and recreated on a different node.
23. Scenario: Terraform Dynamic Blocks
Question: You need to create a Security Group that allows traffic on 20 different ports. Instead
of writing 20 ingressblocks, how can you make your Terraform code cleaner and more
maintainable?
Answer:
● Dynamic Blocks: I would use a dynamic "ingress" block.
● Implementation: I would define a list or map of ports in a variable (e.g., variable
"service_ports" { default = [80, 443, 8080] }). Inside the security group
resource, I use a for_each loop within the dynamic block to iterate through the list and
generate the ingress rules automatically. This makes the code shorter and much easier
to update.
24. Scenario: EKS Private Cluster Security
Question: To meet strict security compliance, you are asked to make an EKS cluster "fully
private." What does this mean for the API Server and the Worker Nodes?
Answer:
● Private API Endpoint: I would disable "Public Access" for the EKS Cluster Endpoint.
This means the Kubernetes API can only be accessed from within the VPC or via a
VPN/Direct Connect.
● Private Subnets: Worker nodes are placed in private subnets with no IGW route.
● VPC Endpoints: To allow nodes to pull images from ECR or send logs to CloudWatch
without hitting the public internet, I must create Interface VPC Endpoints (AWS
PrivateLink) for ECR, S3, and CloudWatch within the VPC.
25. Scenario: Disaster Recovery (RTO/RPO)
Question: Your company requires an RPO (Recovery Point Objective) of 15 minutes for a
critical RDS database. How do you achieve this?
Answer:
● Cross-Region Replication: I would enable RDS Read Replicas in a different AWS
Region.
● Backups: I would ensure automated snapshots are enabled and use AWS Backup to
copy those snapshots to a second region every 15 minutes (or use continuous backup
features).
● Global Datastores: For Aurora, I would use Aurora Global Database, which offers
sub-second replication latency, easily meeting a 15-minute RPO.
26. Scenario: Kubernetes Helm Charts
Question: Why would you use Helm to manage your Kubernetes manifests instead of just
using standard yaml files and kubectl apply?
Answer:
● Templating: Helm allows us to use variables (values.yaml). I can use the same chart for
Dev, QA, and Prod, just changing the values (like CPU limits or replica counts).
● Version Control: Helm keeps a history of "Releases." If a deployment fails, I can run
helm rollback to instantly revert to the previous stable version.
● Dependency Management: If my app needs a database (like Redis), I can include it as
a "sub-chart" dependency, ensuring everything installs together in the correct order.
27. Scenario: Secrets Manager vs. Parameter Store
Question: When would you choose AWS Secrets Manager over AWS Systems Manager
(SSM) Parameter Store?
Answer:
● Secrets Manager: Choose this for highly sensitive data that requires Automatic
Rotation (like RDS passwords). It has built-in integration to change the password in the
DB and the secret at the same time. It is a paid service per secret.
● Parameter Store (SecureString): Choose this for general configuration and simpler
secrets. It is cost-effective (free for standard parameters) but does not offer native
automatic rotation for databases.
28. Scenario: Enforcing IaC Compliance
Question: How do you prevent a team member from accidentally deploying an S3 bucket that is
"Publicly Accessible" via Terraform?
Answer:
● Policy as Code: I would integrate a tool like Checkov, Tfsec, or OPA (Open Policy
Agent) into the CI/CD pipeline.
● Pipeline Gate: The pipeline will run a scan on the terraform plan output. If it detects
a resource that violates security policies (like public_access = true), the build will
fail, and the code cannot be merged or applied.
29. Scenario: Multi-Account AWS Strategy
Question: Why is it a best practice to use multiple AWS accounts (e.g., one for Dev, one for
Prod, one for Shared Services) instead of one large account with many VPCs?
Answer:
● Blast Radius: If one account is compromised or hits a service limit (e.g., API rate limits),
the other environments remain unaffected.
● Billing: It makes "Cost Allocation" much simpler. You can see exactly how much the Dev
team is spending versus Prod.
● Security: You can apply Service Control Policies (SCPs) via AWS Organizations to
restrict entire regions or dangerous services (like GuardDuty/CloudTrail deletion) at the
account level.
30. Scenario: GitOps (ArgoCD/Flux)
Question: What is the main advantage of GitOps (using ArgoCD) compared to a traditional
Jenkins pipeline that runs kubectl apply?
Answer:
● Self-Healing: ArgoCD constantly monitors the cluster. If a developer manually changes
a setting in the cluster (Drift), ArgoCD will detect the discrepancy with Git and
automatically "sync" it back to the desired state.
● Pull vs. Push: In traditional CI (Push), Jenkins needs high-level credentials to the
cluster. In GitOps (Pull), the agent (ArgoCD) lives inside the cluster and pulls changes,
which is more secure as no external credentials are required to be stored in the CI tool.
—------------------------------------------------------------------------------------------------------
Phase 4: Cost, Compliance, and Advanced Operations
(Questions 31–40)
31. Scenario: Cost Optimization with AWS Spot Instances
Question: You want to reduce your EKS compute costs by 60% using Spot Instances. How do
you handle the risk of "Spot Interruption" so your production application doesn't go down?
Answer:
● Diversification: I would use multiple instance types and families in my Auto Scaling
Groups (ASGs) or Karpenter configuration to increase the chances of finding available
capacity.
● Termination Handler: I would deploy the AWS Node Termination Handler in the
cluster. It listens for the 2-minute interruption notice from AWS and triggers a kubectl
drain to safely move pods to other nodes before the instance is reclaimed.
● Workload Selection: I only run stateless, fault-tolerant microservices on Spot. I keep
critical components like Databases or the Kubernetes Control Plane on On-Demand
instances.
32. Scenario: Kubernetes Admission Controllers
Question: Your security team requires that every pod deployed in the cluster must have a
specific label (e.g., team-name). How do you enforce this automatically?
Answer:
● Validating Admission Webhooks: I would use a tool like OPA Gatekeeper or
Kyverno.
● Implementation: I define a policy (Constraint) that inspects every CREATE pod request
sent to the API server. If the team-name label is missing, the Admission Controller
rejects the request with a custom error message, preventing the deployment until the
label is added.
33. Scenario: Terraform Refactoring (The moved Block)
Question: You need to rename a module or a resource in your Terraform code, but you don't
want Terraform to "destroy and recreate" the existing production resource. How do you handle
this?
Answer:
● Moved Block: In newer versions of Terraform (1.1+), I use the moved block.
● Process: I write a block like moved { from = aws_instance.old_name to =
aws_instance.new_name }. This tells Terraform that the resource hasn't actually
changed; only its address in the state file has. This allows me to refactor code cleanly
without any downtime or infrastructure changes.
34. Scenario: Cross-Account ECR Access
Question: You have a "Shared Services" AWS account where all Docker images are stored in
ECR. Your "Production" account needs to pull these images. How do you set this up?
Answer:
● Repository Policy: In the Shared Services account, I apply a Resource-Based Policy
to the ECR repository that grants ecr:BatchGetImage and
ecr:GetDownloadUrlForLayer permissions to the IAM Role or Account ID of the
Production account.
● IAM Permission: In the Production account, I ensure the EKS Node Role has
permission to call ecr:GetAuthorizationToken to authenticate with the registry.
35. Scenario: AWS Direct Connect vs. VPN
Question: A client in Mexico needs to connect their on-premises data center to their AWS VPC.
When would you recommend Direct Connect over a Site-to-Site VPN?
Answer:
● VPN: I recommend this for low-to-medium traffic, quick setup, and lower cost. It runs
over the public internet, so latency can be inconsistent.
● Direct Connect: I recommend this for high-bandwidth needs (1Gbps/10Gbps+),
consistent low latency, and higher security. Since it is a dedicated physical line, it avoids
the public internet entirely, which is often a requirement for financial or large-scale
enterprise data.
36. Scenario: Kubernetes Service Mesh (Istio/Linkerd)
Question: When does a project become "too complex" for standard Kubernetes Services, and
why would you introduce a Service Mesh?
Answer:
● Complexity Indicators: When you need Mutual TLS (mTLS) between every
microservice for "Zero Trust" security, or when you need advanced traffic splitting (e.g.,
1% canary) and detailed "Golden Signal" metrics (latency, errors) without changing
application code.
● Value: A Service Mesh provides a "sidecar" (like Envoy) to every pod that handles
retries, circuit breaking, and encryption automatically, offloading that logic from the
developers.
37. Scenario: Terraform Module Versioning
Question: Multiple teams are using your "VPC Module." You need to make a "breaking change"
to the module. How do you prevent breaking everyone’s infrastructure?
Answer:
● Versioning: I store my modules in a Git Repository (or a Private Registry) and use
Tags (e.g., v1.0.1).
● Source Constraint: In the root configuration, teams should call the module using a
specific version: source = "...?ref=v1.0.0".
● Deployment: I release the new change as v2.0.0. Teams can then choose to upgrade
to the new version at their own pace after testing it in their Dev environments.
38. Scenario: Handling "Heavy" Docker Images
Question: Your Kubernetes pods are taking 5 minutes to start because the Docker image is
very large. How do you fix this?
Answer:
● Image Thinning: Re-evaluate the base image (use alpine or distroless).
● Image Pull Policy: Set imagePullPolicy: IfNotPresent so nodes don't
re-download the same layers.
● Pre-pulling: Use a DaemonSet to pre-pull the heavy image onto all nodes during
off-peak hours or as part of the node provisioning process.
● Amazon ECR Features: Use Soci (Seekable OCI) to allow pods to start before the full
image is downloaded by lazily loading only the necessary files.
39. Scenario: AWS KMS (Key Management Service)
Question: How do you ensure that your EBS volumes and S3 buckets are encrypted using a
key that you control, rather than the default AWS-managed key?
Answer:
● Customer Managed Key (CMK): I create a symmetric key in AWS KMS.
● Key Policy: I define a policy that allows specific IAM roles (like the Terraform execution
role) to use the key for encryption/decryption.
● Enforcement: In Terraform, I specify the kms_key_id in the aws_ebs_volume or
aws_s3_bucket_server_side_encryption_configuration resources. This
ensures "Security at Rest" with full audit logs of who used the key via CloudTrail.
40. Scenario: Zero-Downtime Database Migration
Question: You need to migrate an RDS MySQL database to a larger instance type with minimal
downtime. How do you do it?
Answer:
1. Read Replica: Create a Read Replica of the existing database.
2. Upgrade Replica: Perform the instance type upgrade on the Read Replica (this doesn't
affect the master).
3. Promote: Wait for replication lag to hit zero, then promote the Read Replica to be the
new Standalone Master.
4. DNS Switch: Update the application’s database endpoint (or update the Route53
CNAME) to point to the new master. This reduces downtime from minutes to just a few
seconds.
Phase 5: Deep Orchestration & Security Boundaries
(Questions 41–50)
41. Scenario: Kubernetes Probes (Liveness vs. Readiness vs. Startup)
Question: Your application takes 2 minutes to load a large cache during startup. During this
time, it shouldn't receive traffic, and Kubernetes shouldn't kill it for being "unhealthy." How do
you configure your probes?
Answer:
● Startup Probe: I would use a startupProbe. This probe disables liveness and
readiness checks until the container has passed the startup test. This prevents the
livenessProbe from killing the container before it’s fully started.
● Readiness Probe: Once started, the readinessProbe ensures the pod only receives
traffic when the cache is fully loaded.
● Liveness Probe: This runs continuously after the startup probe passes to catch
deadlocks where the app is "running" but not functioning.
42. Scenario: Terraform Implicit vs. Explicit Dependencies
Question: Usually, Terraform handles resource ordering automatically. When would you actually
need to use an explicit depends_on block?
Answer:
● Hidden Dependencies: I use depends_on when a dependency exists that Terraform
cannot see through code references.
● Example: An IAM Role Policy must be fully attached to a role before an EKS Cluster
starts using that role. If the EKS resource doesn't directly reference the
aws_iam_role_policy resource (only the role itself), Terraform might try to create
both at once. Using depends_on ensures the policy is active first to avoid "Access
Denied" errors during cluster creation.
43. Scenario: AWS Savings Plans vs. Reserved Instances
Question: The Finance department wants to commit to a 1-year contract to reduce AWS costs.
Would you recommend EC2 Instance Savings Plans or Compute Savings Plans?
Answer:
● Compute Savings Plans: I would recommend these for maximum flexibility. They apply
to EC2, Lambda, and Fargate regardless of instance family, region, or operating system.
● EC2 Instance Savings Plans: I only recommend these if the infrastructure is extremely
stable (e.g., using only m5.large in us-east-1 for a year), as they offer higher
discounts (up to 72%) but lock you into a specific instance family in a specific region.
44. Scenario: Kubernetes Network Policies
Question: By default, all pods in a Kubernetes cluster can talk to each other. How do you
implement a "Zero Trust" network for a sensitive Database pod?
Answer:
● Default Deny: I start by applying a "Default Deny" NetworkPolicy to the namespace.
● Ingress Rules: I then create a specific policy for the Database pod that only allows
Ingress on the DB port (e.g., 5432) from pods with a specific label (e.g., role:
backend-api).
● Requirement: I must ensure the cluster is using a CNI plugin that supports Network
Policies, such as Calico or the Amazon VPC CNI with network policy support enabled.
45. Scenario: Terraform null_resource and local-exec
Question: You need to run a local shell script or a docker push command as part of your
Terraform deployment. How do you achieve this?
Answer:
● null_resource: I use a null_resource which doesn't create any physical
infrastructure but allows me to trigger logic.
● Provisioner: Inside the resource, I use a local-exec provisioner to run the command
on the machine executing Terraform.
● Triggers: I use the triggers block (often mapped to a resource ID or a file hash) so
that the script re-runs only when the underlying infrastructure or script content changes.
46. Scenario: AWS IAM Permission Boundaries
Question: How do you allow a Junior DevOps engineer to create IAM Roles for their
applications without giving them the power to create an "Admin" role for themselves?
Answer:
● Permission Boundary: I create a managed policy that defines the maximum
permissions any role can have (e.g., only S3 and CloudWatch access).
● Enforcement: I attach an IAM policy to the Junior engineer that allows
iam:CreateRole only if they also attach the specified "Permission Boundary" to the
new role. If they try to create a role without it or with more power than the boundary
allows, AWS will deny the request.
47. Scenario: Blue/Green Deployments with AWS App Mesh
Question: You are using EKS and want to do a Blue/Green deployment where you shift traffic
based on specific HTTP headers (e.g., only "Beta" testers see the new version). How do you
handle this?
Answer:
● Service Mesh: I would use AWS App Mesh (based on Envoy).
● Virtual Router: I configure a VirtualRouter and VirtualNodes for the Blue and
Green versions.
● Route Matching: I define a route that looks for a specific HTTP header. If the header
Env: Beta is present, the traffic is routed to the Green VirtualNode; otherwise, it
goes to Blue. This allows for highly granular "Dark Launches."
48. Scenario: Handling Large Terraform State Files
Question: Your Terraform state file has grown to 50MB, and terraform plan is taking 10
minutes to run. How do you optimize this?
Answer:
● State Splitting: I would break the large monolithic state into smaller, decoupled states
(e.g., networking.tfstate, database.tfstate, app.tfstate).
● Remote State Data Source: I use terraform_remote_state to allow the "app" layer
to read outputs (like VPC IDs) from the "networking" layer.
● Targeting: For urgent fixes, I use the -target flag to only refresh specific resources,
though this is a temporary fix.
● Parallelism: I can increase the -parallelism=n flag (default is 10) if the AWS API
limits allow for faster resource checking.
49. Scenario: Docker Image Signing (Notary/Cosign)
Question: How do you prevent a "Man-in-the-Middle" attack where someone replaces your
production Docker image with a malicious one in the registry?
Answer:
● Image Signing: I use a tool like Sigstore Cosign or Docker Notary.
● Pipeline Integration: In the CI pipeline, after the image is built and pushed, I sign the
image digest using a private key (stored in AWS KMS).
● Admission Controller: In Kubernetes, I use an admission controller (like Kyverno or
Policy Reporter) that validates the signature. If the image is not signed by our trusted
key, the pod is blocked from starting.
50. Scenario: Prometheus/Grafana Alerting (SRE focus)
Question: You are getting too many "Symptom-based" alerts (e.g., CPU is 90%). How do you
transition to "User-facing" alerts?
Answer:
● SLIs/SLOs: I would focus on Service Level Indicators (SLIs) like Error Rate and
Latency (the "Golden Signals").
● Alerting on Symptoms: Instead of alerting on CPU, I alert if the "HTTP 5xx Error Rate"
exceeds 1% over a 5-minute window.
● Burn Rate: I would set up "Error Budget Burn Rate" alerts. This notifies the team if we
are consuming our monthly allowed "unavailability" too quickly, which is much more
meaningful than a temporary CPU spike.
Phase 6: Governance, Migration, and Service Networking
(Questions 51–60)
51. Scenario: Advanced K8s Scheduling (Taints & Tolerations)
Question: You have a specific set of Nodes with high-performance GPUs. How do you ensure
only the "Machine Learning" pods run on these nodes, and regular "Web" pods are kept off?
Answer:
● Taints: I would apply a taint to the GPU nodes (e.g., kubectl taint nodes
node1 hardware=gpu:NoSchedule). This repels any pod that does not have a
matching toleration.
● Tolerations: I would then add a toleration to the "Machine Learning" pod manifest
that matches the taint.
● Node Affinity: To be 100% sure the ML pods only go to those nodes (and don't end up
on standard nodes), I would also use nodeAffinity with a label like gpu=true.
52. Scenario: Terraform "Brownfield" Migration
Question: You joined a company that has 50 EC2 instances created manually via the Console.
How do you bring them under Terraform management without destroying them?
Answer:
1. Skeleton Code: I first write the Terraform resource blocks (e.g., resource
"aws_instance" "legacy_app") for the existing instances.
2. Terraform Import: I run terraform import aws_instance.legacy_app
<instance-id>. This pulls the real-world state into the terraform.tfstate file.
3. Plan & Align: I run terraform plan. Initially, it will show many differences. I manually
update the attributes in my .tffiles until terraform plan shows "No changes,"
meaning the code perfectly matches the existing infrastructure.
53. Scenario: AWS Service Control Policies (SCPs)
Question: How can you ensure that no one—not even the "Root" user of a member
account—can delete the S3 buckets containing your CloudTrail logs?
Answer:
● AWS Organizations: I would use a Service Control Policy (SCP) applied at the
Organization Root or the specific Organizational Unit (OU).
● Policy: The SCP would contain a Deny statement for the s3:DeleteBucket action on
the specific ARNs of the logging buckets. Because a Deny in an SCP overrides any local
Allow (even for an Admin/Root user), the buckets remain protected across the entire
organization.
54. Scenario: Automated Canary Analysis
Question: In a CI/CD pipeline, how do you mathematically decide if a "Canary" deployment is
successful or should be rolled back?
Answer:
● Kayenta/Spinnaker: I would use a tool like Kayenta for automated canary analysis.
● Statistical Comparison: The pipeline compares "Golden Signals" (latency, error rate,
throughput) between the "Baseline" (current version) and the "Canary" (new version)
using a statistical test (like the Mann-Whitney U test).
● Thresholds: We set a score (e.g., 0-100). If the score is below 80, the pipeline
automatically triggers a rollback. This removes human bias from the deployment
process.
55. Scenario: Kubernetes Pod Security (PSS)
Question: With PodSecurityPolicies (PSP) being deprecated, how do you now prevent pods
from running as the "Root" user in Kubernetes?
Answer:
● Pod Security Admission (PSA): I use the built-in Pod Security Standards. I label the
namespace with pod-security.kubernetes.io/enforce: restricted.
● SecurityContext: This forces every deployment in that namespace to have a
securityContext with runAsNonRoot: trueand allowPrivilegeEscalation:
false.
● Alternative: For more complex logic, I would use Kyverno or OPA Gatekeeper to
validate the security context of every incoming Pod manifest.
56. Scenario: AWS PrivateLink (Interface Endpoints)
Question: You have a "Provider" VPC and a "Consumer" VPC in different AWS accounts. How
do you allow the Consumer to access a private service in the Provider VPC without using VPC
Peering?
Answer:
● VPC Endpoint Service: In the Provider VPC, I create a Network Load Balancer (NLB)
in front of the service and then create a VPC Endpoint Service.
● Interface Endpoint: In the Consumer VPC, I create an Interface VPC Endpoint
pointing to the Provider's service.
● Benefit: This uses the AWS private backbone and only exposes the specific service
port, rather than connecting the entire network like VPC Peering does.
57. Scenario: Stuck Terraform State Lock
Question: You are trying to run terraform apply, but you get an error saying the state is
locked by another process, yet you know no one else is running it. How do you fix this?
Answer:
1. Verify: I check with the team to ensure no CI/CD pipeline is currently running.
2. Lock ID: I identify the Lock ID from the error message.
3. Force Unlock: I run terraform force-unlock <LOCK_ID>.
● Precaution: This is a last resort. Since we use DynamoDB for locking, I would also
check the DynamoDB table to see if the entry was orphaned due to a crash or a network
timeout.
58. Scenario: Centralized Logging at Scale
Question: Your application generates 1TB of logs per day. Sending everything to CloudWatch is
becoming too expensive. What is your alternative?
Answer:
● Log Routing: I would use Fluent Bit as a DaemonSet on Kubernetes nodes.
● Filtering: I would configure Fluent Bit to send only "Error" and "Critical" logs to
CloudWatch for immediate alerting.
● Cold Storage: I would send the full stream of logs (Info/Debug) to an S3 Bucket via
Kinesis Data Firehose.
● Analysis: For troubleshooting, I can use Amazon Athena to query the logs directly in
S3 using SQL, which is significantly cheaper than storing them in CloudWatch Logs or
an OpenSearch cluster.
59. Scenario: Route 53 Routing Policies
Question: A client wants their users in Europe to hit a server in Frankfurt and users in the US to
hit a server in Virginia. How do you configure this?
Answer:
● Geolocation Routing: I would use Route 53 Geolocation Routing.
● Records: I create two records for the same domain name. One record points to the
Frankfurt ALB and is set to the location "Europe." The second record points to the
Virginia ALB and is set to the location "North America."
● Default: I also create a "Default" record for traffic from any other location to ensure
global availability.
60. Scenario: K8s HPA with Custom Metrics
Question: Your application's performance is tied to "Queue Depth" in SQS, not CPU or
Memory. How do you scale your Kubernetes pods based on the number of messages in SQS?
Answer:
● Prometheus Adapter / KEDA: I would use KEDA (Kubernetes Event-driven
Autoscaling).
● ScaledObject: I define a ScaledObject that connects to the AWS SQS trigger.
● Scaling: KEDA monitors the SQS queue size via the AWS API and automatically
updates the HPA to scale the number of pods up or down based on the exact number of
messages waiting to be processed.
Phase 7: Modernization, Advanced Access &
Performance (Questions 61–70)
61. Scenario: DR Strategies (Pilot Light vs. Warm Standby)
Question: You are asked to design a Disaster Recovery (DR) plan for a mission-critical app
with an RTO of 30 minutes. Which strategy do you choose, and what is the infrastructure setup?
Answer:
● Strategy: I would choose Warm Standby.
● Setup: In a secondary region, I maintain a scaled-down version of the infrastructure
(e.g., smaller EC2 instances or a minimum EKS node count). The database is kept in
sync via Cross-Region Replication.
● Failover: When a disaster occurs, the CI/CD pipeline or an automation script scales up
the secondary environment and Route53 health checks flip the traffic. This meets the
30-minute RTO, whereas "Pilot Light" might take longer as it requires starting the
application servers from scratch.
62. Scenario: EKS Access Entries (New AWS Feature)
Question: Previously, we used the aws-auth ConfigMap to grant IAM users access to EKS.
AWS now recommends EKS Access Entries. Why is this better?
Answer:
● Decoupling: Access Entries allow us to manage cluster access directly through the
AWS API or Terraform without editing a ConfigMap inside Kubernetes.
● Security: It simplifies the process of granting permissions and reduces the risk of
corrupting the aws-auth YAML file, which could lock everyone out of the cluster. It also
allows for easier auditing of who has access to the cluster through IAM.
63. Scenario: Terraform Policy as Code (Sentinel/Checkov)
Question: Your organization requires that all S3 buckets must have "Versioning" and
"Encryption" enabled. How do you enforce this automatically before the infrastructure is even
created?
Answer:
● Tooling: I would use Checkov or Terraform Sentinel.
● Implementation: I integrate the tool into the CI/CD pipeline. Before terraform
apply, the tool scans the terraform planoutput. If it finds an S3 bucket resource
where versioning is not enabled, it returns a non-zero exit code, failing the build and
preventing the deployment of non-compliant infrastructure.
64. Scenario: Automated Remediation with AWS Config
Question: If a developer accidentally opens an SSH port (22) to the world (0.0.0.0/0), how can
you detect and close it automatically within seconds?
Answer:
● Detection: I enable AWS Config with a managed rule restricted-common-ports.
● Remediation: I associate an SSM Automation Document with the rule. When AWS
Config detects the non-compliant Security Group, it triggers the SSM document to
automatically remove the broad ingress rule, effectively "self-healing" the security
posture without manual intervention.
65. Scenario: K8s Storage - EBS vs. EFS
Question: You have a WordPress application running on Kubernetes that needs multiple pods
to write to the same shared file system. Would you use ebs-csi-driver or
efs-csi-driver?
Answer:
● Choice: I would use the EFS CSI Driver.
● Reason: EBS volumes are block storage and generally follow ReadWriteOnce (RWO),
meaning they can only be attached to one node at a time. EFS is file storage that
supports ReadWriteMany (RWX), allowing multiple pods across different nodes to read
and write to the same volume simultaneously, which is required for shared content
directories.
66. Scenario: CI/CD Multi-Architecture Builds
Question: Some of your EKS nodes are running on Graviton (ARM) and some on Intel (x86).
How do you handle this in your CI/CD pipeline?
Answer:
● Docker Buildx: I use docker buildx to create a Multi-Arch Image.
● Manifest: The pipeline builds the image for both linux/amd64 and linux/arm64 and
pushes them to ECR under a single tag. When Kubernetes pulls the image, the
container runtime automatically selects the correct version based on the node's CPU
architecture.
67. Scenario: Migration - Legacy WebSphere to EKS
Question: You are migrating a legacy WebSphere application to AWS. What is the most
efficient path to modernize it for a DevOps environment?
Answer:
● Re-platforming: I would containerize the application components. Instead of the full
WebSphere Application Server (WAS), I would move the code to Liberty, which is
lightweight and designed for containers.
● Deployment: I would then deploy the Liberty-based containers onto Amazon EKS. This
allows us to use standard CI/CD pipelines, Kubernetes HPA for scaling, and modern
monitoring tools while maintaining the Java EE application logic.
68. Scenario: Terraform 1.5+ import Block
Question: How does the new import block in Terraform 1.5 change the way we bring existing
cloud resources into code?
Answer:
● Code Generation: Unlike the old terraform import command, the import block is
written in the code.
● Benefit: When I run terraform plan, Terraform can now generate the configuration
code for me. This is much faster than manually writing the resource blocks and then
running a command-line import, making it much easier to migrate "manual" infrastructure
to IaC.
69. Scenario: Global Traffic - AWS Global Accelerator
Question: A client's application in Mexico is being accessed by users in Singapore, but they are
experiencing high network latency. ALB is already in use. How do you optimize this?
Answer:
● Global Accelerator: I would place an AWS Global Accelerator in front of the ALB.
● Optimization: Global Accelerator provides static IP addresses and routes traffic over the
AWS Private Global Network instead of the public internet. This reduces the number of
"hops" and significantly lowers latency and jitter for international users by entering the
AWS network at the nearest Edge Location.
70. Scenario: K8s Sidecar Containers (Native Support)
Question: In K8s 1.29+, there is a new feature for "Sidecar Containers." How does this differ
from the old way of just putting two containers in one pod?
Answer:
● Lifecycle Management: Previously, if a sidecar (like a log-shipper) crashed, it might not
affect the main app, or if the main app finished, the sidecar would keep running.
● Native Sidecars: By setting restartPolicy: Always on an initContainer,
Kubernetes now treats it as a sidecar. This ensures the sidecar starts before the main
container and is shut down after the main container finishes, solving the common
problem of logs being missed or jobs never completing because the sidecar stayed alive.
Phase 8: Enterprise Governance & Advanced
Observability (Questions 71–80)
71. Scenario: IAM Roles Anywhere
Question: You have a legacy server running in a data center in Chennai that needs to securely
access an S3 bucket in AWS. You don't want to use permanent IAM Access Keys. How do you
solve this?
Answer:
● Solution: I would use AWS IAM Roles Anywhere.
● Mechanism: I would set up a Trust Anchor using our on-premises Certificate Authority
(CA). The legacy server uses its local X.509 certificate to exchange for temporary AWS
credentials via the IAM Roles Anywhere service.
● Benefit: This provides the same security benefits as IAM Roles for EC2 (temporary,
rotating credentials) but for servers outside of AWS, completely eliminating the risk of
leaked long-term secret keys.
72. Scenario: Kubernetes Ephemeral Containers
Question: You have a "distroless" container running in production that is crashing. Since it has
no shell (no sh or bash), how do you troubleshoot it?
Answer:
● Ephemeral Containers: I would use the kubectl debug command to attach an
Ephemeral Container to the running pod.
● Implementation: I would use an image like busybox or ubuntu as the debug
container. This container shares the same process namespace as the crashing
container, allowing me to inspect logs, files, and network connections without needing a
shell in the original production image.
73. Scenario: OpenTelemetry (OTel)
Question: Why is the industry moving toward OpenTelemetry for observability instead of using
vendor-specific agents (like Datadog or CloudWatch agents)?
Answer:
● Vendor Neutrality: OpenTelemetry provides a standardized way to collect traces,
metrics, and logs. This prevents "vendor lock-in." If the company decides to switch from
New Relic to AWS Managed Prometheus/Grafana, we only change the "exporter"
configuration, not the application code.
● Unified Pipeline: With an OTel Collector, I can receive data once and fan it out to
multiple destinations (e.g., S3 for long-term storage and Jaeger for real-time tracing)
simultaneously.
74. Scenario: AWS Control Tower & Account Factory
Question: Your company is growing fast and needs to spin up 5 new AWS accounts every
month for different projects. How do you ensure they all follow the same security and networking
standards?
Answer:
● Control Tower: I would implement AWS Control Tower.
● Account Factory: I would use the "Account Factory" to automate account creation. This
ensures every new account is automatically enrolled in our organization, has GuardDuty
and CloudTrail enabled, and is governed by our Service Control Policies (SCPs) from
day one. This provides "Governance at Scale."
75. Scenario: Terraform metadata (pre-conditions/post-conditions)
Question: How can you use Terraform to prevent a deployment if someone accidentally tries to
provision a resource that is too expensive (e.g., an m5.24xlarge instance)?
Answer:
● Post-conditions: I can add a lifecycle block with a postcondition to the
resource.
● Check: I can write a check that validates the instance_type. If the type doesn't match
an "Allowed" list, Terraform will fail the apply and roll back.
● Alternative: For more robust enforcement, I would use Sentinel (Terraform Enterprise)
or OPA in the pipeline to scan the plan and reject any instance types that are not in the
approved "Cost Tier."
76. Scenario: Kubernetes GitOps "App of Apps" Pattern
Question: You are using ArgoCD to manage 100 microservices. Adding them one by one to
ArgoCD is tedious. What is the professional way to manage this?
Answer:
● App of Apps: I would implement the "App of Apps" pattern.
● Structure: I create one "Master" ArgoCD Application that points to a Git folder
containing the manifests for all other applications.
● Automation: When a new microservice is added to the Git folder, the Master App
detects it and automatically creates a new ArgoCD Application for that service. This
makes the entire cluster's state self-documenting and fully automated.
77. Scenario: AWS WAF & Shield (DDoS Protection)
Question: Your public-facing API is being targeted by a "Low and Slow" HTTP DDoS attack that
CloudWatch metrics aren't catching. How do you mitigate this?
Answer:
● AWS WAF: I would enable AWS WAF (Web Application Firewall) on the ALB.
● Rate Limiting: I would implement a "Rate-based rule" that blocks any IP address that
exceeds 100 requests per minute.
● Shield Advanced: I would recommend AWS Shield Advanced, which provides a
dedicated DDoS Response Team (DRT) and automatic proactive monitoring of layer 7
traffic patterns to block sophisticated attacks before they reach the application.
78. Scenario: Right-sizing (Cost Optimization)
Question: You notice your AWS bill is high, but all your EC2 instances show only 10% CPU
usage. What is your process for "Right-sizing"?
Answer:
● Compute Optimizer: I would use AWS Compute Optimizer to get data-driven
recommendations.
● Analysis: I check for "Idle" vs "Underutilized" resources.
● Action: I would transition to T3/T4g (Burstable) instances for low-baseline workloads or
move them to AWS Fargate where we only pay for the exact CPU/RAM the process
consumes. I would also check if Graviton (ARM)instances can provide a better
price-performance ratio.
79. Scenario: VPC Lattice
Question: You have services in 5 different VPCs and some in a Kubernetes cluster. Managing
peering and private DNS is becoming a nightmare. Is there a modern AWS way to handle
service-to-service communication?
Answer:
● Amazon VPC Lattice: This is a newer service that provides a consistent way to
connect, secure, and monitor services across VPCs and clusters.
● Benefit: It handles the networking (no need for VPC Peering/Transit Gateway for this
specific use case) and provides built-in Layer 7 routing and authentication. It simplifies
service discovery across the entire AWS environment without managing complex route
tables.
80. Scenario: Handling Secrets in Multi-Region Terraform
Question: You have a Terraform project deploying to both US and Europe. You use AWS
Secrets Manager. How do you ensure the application in Europe can access its secrets if the US
region goes down?
Answer:
● Secret Replication: I would use the Multi-Region Secret feature in AWS Secrets
Manager.
● Implementation: I define the secret in the primary region (US) and tell AWS to
automatically replicate it to the secondary region (Europe). AWS keeps the secret values
and the encryption keys (via KMS multi-region keys) in sync.
● Application Logic: The application is coded to look for the secret in its local region. If
the primary region fails, the replica is already there and ready for use.
Phase 9: High-Scale Operations & Modern Tooling
(Questions 81–90)
81. Scenario: EKS IP Address Exhaustion
Question: You are running a large EKS cluster in a VPC with limited CIDR space. Your pods
are failing to start with Network@Internal errors because there are no available IP
addresses. How do you solve this without creating a new VPC?
Answer:
● Custom Networking: I would enable VPC CNI Custom Networking. This allows me to
assign a separate CIDR block (secondary IPv4 CIDR) to the VPC specifically for the
pods, while the nodes stay on the primary CIDR.
● Prefix Delegation: I would also enable Prefix Delegation, which allows each Elastic
Network Interface (ENI) to hold a "prefix" of IPs (/28) rather than individual IPs. This
significantly increases the pod density per node and reduces the pressure on the VPC’s
primary IP space.
82. Scenario: Terraform 1.6+ Testing Framework
Question: In the past, we used external tools like Terratest (Go) or Kitchen-Terraform
to test our code. How does the new native terraform test command change this?
Answer:
● Native Integration: Terraform 1.6 introduced a native testing framework using HCL. I
can now write test files (ending in .tftest.hcl) that define run blocks to execute
plans or applies and assert blocks to check if the outputs or resource attributes match
expectations.
● Efficiency: This is much faster and easier to maintain because I don't need to learn Go
or Ruby. It allows us to catch logical errors (like an S3 bucket being created without
encryption) in the CI/CD pipeline before any real infrastructure is ever touched.
83. Scenario: Karpenter vs. Cluster Autoscaler
Question: Why is Karpenter becoming the preferred choice for autoscaling EKS clusters over
the traditional Cluster Autoscaler?
Answer:
● Provisioning Speed: Cluster Autoscaler works by interacting with AWS Auto Scaling
Groups (ASGs). It’s "node-group aware." Karpenter is "group-less" and talks directly to
the EC2 API, launching nodes in seconds rather than minutes.
● Bin-packing: Karpenter looks at the specific resource requests of pending pods and
selects the cheapest and most efficient instance type from the entire EC2 catalog (e.g.,
choosing a c6g.large if only CPU is needed). This leads to much better cost
optimization and less wasted capacity.
84. Scenario: EKS Secrets Encryption at Rest
Question: By default, Kubernetes secrets are stored unencrypted in etcd. How do you
implement enterprise-grade security for secrets in an AWS EKS environment?
Answer:
● KMS Integration: I would enable KMS Envelope Encryption for the EKS cluster.
During cluster creation (or update), I specify a Customer Managed Key (CMK) from AWS
KMS.
● Mechanism: When a secret is created, the EKS control plane uses the KMS key to
encrypt it before it ever hits the etcd database.
● External Secrets: For even better security, I would use the External Secrets Operator,
which syncs secrets directly from AWS Secrets Manager into Kubernetes, ensuring the
"source of truth" remains outside the cluster.
85. Scenario: Cloud-Native Buildpacks (CNB)
Question: A developer doesn't want to write or maintain a Dockerfile. How can your CI/CD
pipeline still produce a secure, optimized container image for them?
Answer:
● Buildpacks: I would integrate Cloud-Native Buildpacks (e.g., using pack or Google’s
buildpacks) into the pipeline.
● Process: The buildpack automatically detects the language (Java, Python, Node.js),
handles the dependencies, and creates a layered OCI-compliant image.
● Benefits: This ensures consistency across all microservices, automatically applies
security patches to the base OS layer without developer intervention, and follows all
Docker best practices (like non-root users).
86. Scenario: Centralized Egress via Transit Gateway
Question: Your security team requires that all traffic leaving your 20 VPCs for the public internet
must pass through a centralized set of Firewalls/Inspectors. How do you design this?
Answer:
● Inspection VPC: I would create a centralized "Inspection" or "Egress" VPC containing a
NAT Gateway and a Transit Gateway (TGW).
● Routing: I would use Transit Gateway Route Tables to route all traffic (0.0.0.0/0) from
the spoke VPCs to the Inspection VPC.
● Enforcement: This ensures that all outbound traffic is logged and inspected by a central
security appliance (like AWS Network Firewall or a Palo Alto VM) before it hits the
internet, providing a single choke point for security control.
87. Scenario: Kubernetes Volume Snapshots
Question: You are running a stateful application on EKS using EBS. How do you automate
backups of the data without taking the application offline?
Answer:
● CSI Snapshotter: I would install the External Snapshotter controller and ensure the
EBS CSI driver is active.
● Implementation: I define a VolumeSnapshotClass. To take a backup, I create a
VolumeSnapshot resource pointing to the PersistentVolumeClaim (PVC).
● Restore: If data is lost, I can create a new PVC and specify the VolumeSnapshot as
the dataSource. This allows for point-in-time recovery of persistent data directly
through Kubernetes manifests.
88. Scenario: Event-Driven Scaling with KEDA
Question: You have a worker pod that processes messages from an AWS SQS queue.
Standard HPA (CPU/RAM) isn't scaling it fast enough. How do you scale based on the actual
number of messages?
Answer:
● KEDA: I would deploy KEDA (Kubernetes Event-driven Autoscaling).
● Trigger: I configure a ScaledObject that targets the SQS queue.
● Logic: KEDA polls the SQS ApproximateNumberOfMessagesVisible metric. If the
queue grows, KEDA instructs the HPA to scale up the pods. If the queue is empty, KEDA
can even scale the pods down to zero, saving significant costs during idle periods.
89. Scenario: AWS IAM Identity Center (SSO)
Question: Your team is growing, and managing individual IAM Users is becoming a security
risk. What is the modern AWS recommendation for managing human access?
Answer:
● IAM Identity Center: I would transition from IAM Users to AWS IAM Identity Center
(formerly AWS SSO).
● Permission Sets: I create Permission Sets (e.g., "DevOpsAdmin") and map them to
groups in our external Identity Provider (like Azure AD or Okta).
● Benefit: Engineers log in once via a portal, can access multiple accounts with short-lived
credentials, and we can instantly revoke access for everyone across the entire
organization from a single dashboard.
90. Scenario: Chaos Engineering with AWS FIS
Question: How do you prove that your EKS cluster is truly "Highly Available" and will survive an
AZ failure?
Answer:
● AWS Fault Injection Service (FIS): I would run a Chaos Engineering experiment using
AWS FIS.
● The Test: I would configure an experiment to terminate all EC2 instances in a specific
Availability Zone or inject network latency between nodes.
● Validation: While the experiment is running, we monitor our "Steady State" (e.g.,
successful login rate). If our application survives the AZ "outage" without dropping user
requests, we have proven our resilience. If it fails, we use the data to fix the architecture
before a real outage happens.
Phase 10: Strategy, Leadership & Future-Proofing
(Questions 91–100)
91. Scenario: Choosing a New Technology Stack
Question: A project manager asks you to adopt a brand-new tool because "it’s trending." How
do you evaluate whether to bring a new technology into your production environment?
Answer:
● Evaluation Framework: I evaluate tools based on four pillars:
1. Security: Does it have enterprise-grade security, and is it compliant with our
standards?
2. Maintainability: Is there a strong community/vendor support, and does the team
have the skills to manage it?
3. ROI: Does it solve a problem faster or cheaper than our current tools?
4. Integration: Does it play well with our existing AWS/Kubernetes ecosystem?
● PoC: I always suggest a Proof of Concept (PoC) with a small, non-critical workload
before making a full-scale commitment.
92. Scenario: Large-Scale Migration (The 6 Rs)
Question: Your company wants to move 500 legacy applications from on-premises to AWS.
How do you decide which ones to migrate and how?
Answer:
● The 6 Rs Framework: I categorize every application into one of the following:
○ Rehost (Lift & Shift): Quickest, moving VMs as-is.
○ Replatform: Minor changes (e.g., moving a DB to RDS).
○ Refactor: Re-architecting for cloud-native (e.g., moving WebSphere to EKS).
○ Repurchase: Moving to a SaaS equivalent.
○ Retire: Decommissioning old apps.
○ Retain: Keeping it on-prem for now.
● Priority: I prioritize based on business value vs. technical complexity, usually starting
with a few "low-hanging fruit" apps to build momentum.
93. Scenario: Engineering-Led FinOps
Question: Cost optimization is often seen as a "Finance" problem. How do you instill a "FinOps"
culture within your engineering team?
Answer:
● Visibility: I advocate for tagging resources (e.g., Owner, Project, Environment) so
engineers can see the cost of their own infrastructure in dashboards.
● Unit Economics: Instead of saying "save money," I talk about "unit cost"—for example,
"How much does it cost us to process one user login?"
● Incentives: I encourage identifying idle resources and using Spot instances or Graviton
processors during the design phase, making cost-efficiency a core part of the "Definition
of Done."
94. Scenario: Serverless vs. Containers
Question: When would you recommend AWS Lambda (Serverless) over Amazon EKS
(Kubernetes) for a new microservice?
Answer:
● Choose Lambda: For event-driven tasks (like file processing or webhooks),
unpredictable traffic, or small APIs where you want zero management overhead and a
"pay-as-you-go" model.
● Choose EKS: For complex, long-running processes, workloads that need consistent
performance (no "cold starts"), or when the team requires deep control over the
underlying runtime environment and networking.
95. Scenario: Compliance in Highly Regulated Industries
Question: How do you ensure your infrastructure remains compliant with standards like
PCI-DSS or HIPAA when you are deploying changes 10 times a day?
Answer:
● Continuous Compliance: I use AWS Config to track resource changes and AWS
Audit Manager to collect evidence automatically.
● Guardrails: I implement Service Control Policies (SCPs) and IAM Permission
Boundaries to prevent non-compliant actions (like creating an unencrypted DB) from
ever happening.
● Audit Trails: Every change is made via IaC (Terraform), meaning every "infrastructure
change" is documented in Git with a peer review and an audit trail.
96. Scenario: Multi-Region Active-Active Architecture
Question: For a global application, how do you handle an "Active-Active" setup where users in
Mexico and users in Singapore both need low latency and consistent data?
Answer:
● Traffic Routing: Use Route 53 Geoproximity or Global Accelerator to route users to
the nearest healthy region.
● Data Consistency: Use Amazon Aurora Global Database or DynamoDB Global
Tables for multi-region replication.
● Conflict Resolution: For DynamoDB, use "Last Writer Wins" or application-level logic to
handle simultaneous writes to the same record in different regions.
97. Scenario: Platform Engineering & Internal Developer Portals (IDP)
Question: Developers are complaining that setting up a new environment takes too long. How
do you solve this at an enterprise scale?
Answer:
● IDP: I would implement a Platform Engineering approach by creating an Internal
Developer Portal (like Backstage).
● Self-Service: We create "Golden Templates" in Terraform. A developer can go to the
portal, click "New Service," and it automatically provisions a VPC, EKS Namespace,
CI/CD pipeline, and a "Hello World" app in 5 minutes without needing a DevOps
engineer to help.
Getty ImagesExplore
98. Scenario: Software Bill of Materials (SBOM) & Supply Chain Security
Question: Recent attacks have targeted the "Supply Chain." How do you ensure the
open-source libraries your developers use are safe?
Answer:
● SBOM: I integrate tools like Syft or Trivy into the pipeline to generate an SBOM for
every container image.
● Vulnerability Management: We scan that SBOM against databases of known
vulnerabilities (CVEs).
● Private Repositories: We use AWS CodeArtifact to store approved versions of
libraries, preventing developers from pulling "malicious" packages directly from the
public internet.
99. Scenario: Hybrid Cloud Networking (Direct Connect & Outposts)
Question: Your data must stay in Mexico for legal reasons, but you want to use AWS tools.
How do you handle this?
Answer:
● AWS Outposts: I would suggest AWS Outposts to bring AWS hardware and services
directly into the local data center in Mexico.
● Connectivity: I would use AWS Direct Connect to establish a private, high-speed
connection between the local data center and the nearest AWS Region (like US-East).
This allows for a consistent hybrid experience while keeping data residency local.
100. Scenario: Handling a Major Production Outage
Question: Describe a time you led a team through a critical production failure. What was your
process?
Answer:
● Incident Response: 1. Triage: Identify the scope. Is it all users or just some? 2.
Mitigation: Focus on "Restoring Service" first (e.g., rolling back the last change), even if
you don't fully understand the root cause yet. 3. Communication: Keep stakeholders
updated every 15–30 minutes so they don't have to ask for status.
● Blameless Post-Mortem: After the fix, I lead a meeting to find out what failed (not who
failed). We document the "Action Items" and put them into the next sprint to ensure the
same failure never happens again.
