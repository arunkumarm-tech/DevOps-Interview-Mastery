Scenario 4: AWS Multi-Region Deployment (Full Practical Lab)
🎯 1. The Interviewer Response (The Talk Track)
Question: "How do you use Terraform to deploy infrastructure to multiple AWS Regions simultaneously within the same codebase?"

The Professional Answer:
"In enterprise-grade architectures, I use Terraform Provider Aliases. By default, a provider block is tied to one region. However, by defining a secondary provider with a unique alias, I can target multiple regions (like us-east-1 and eu-west-1) in a single execution. This is essential for Disaster Recovery (DR) and global low-latency applications. It allows me to manage the global state in one place while ensuring resources in different continents are perfectly synced."

🛠️ 2. Step-by-Step Practical Execution
Phase A: Creating the Global Infrastructure Code
We will create two SNS topics: one in Virginia (US) and one in Ireland (Europe).

1. File Creation:

Action: In VS Code, create a new file named multi-region.tf inside the phase-1-infrastructure folder.

Content:

Terraform
# 1. Primary Provider (US East - N. Virginia)
provider "aws" {
  region = "us-east-1"
}

# 2. Secondary Provider (EU West - Ireland)
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# 3. Resource in US (Default)
resource "aws_sns_topic" "us_alerts" {
  name = "global-alerts-us"
}

# 4. Resource in Europe (Using the Alias)
resource "aws_sns_topic" "eu_alerts" {
  provider = aws.ireland  # This tells Terraform to use the Ireland alias
  name     = "global-alerts-eu"
}
2. Terminal Commands to Deploy:
Open your terminal inside the phase-1-infrastructure folder and run:

Bash
# Initialize to download the secondary region plugins
terraform init

# Plan to see the 2 resources in 2 different regions
terraform plan

# Apply the global changes
terraform apply -auto-approve
🧪 3. Validation and Testing (Proof of Concept)
Once Terraform finishes, you must verify the resources exist in the actual AWS regions using the CLI.

Step 1: Verify the US Topic

Bash
aws sns list-topics --region us-east-1
Expected: You should see global-alerts-us in the list.

Step 2: Verify the Europe Topic

Bash
aws sns list-topics --region eu-west-1
Expected: You should see global-alerts-eu in the list.

💡 4. Master Command Glossary
alias : The Terraform keyword used to define multiple providers.

provider = aws.ireland : Tells a resource to use the Ireland alias.

terraform init : Required after adding a new region to download plugins.

aws sns list-topics : CLI command to verify resources in specific regions.

--region eu-west-1 : CLI flag to switch focus between AWS regions.


🚀 5. Final Deployment to Git
Bash
git add multi-region.tf
git add SCENARIO-4-MULTI-REGION.md
git commit -m "docs: finalize scenario 4 source"
git push origin main