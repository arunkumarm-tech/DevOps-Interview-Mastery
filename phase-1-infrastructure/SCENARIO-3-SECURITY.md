# Scenario 3: CI/CD Pipeline Security & Secret Management (Full Practical Lab)

## 🎯 1. The Interviewer Response (The Talk Track)
**Question:** *"How do you securely manage sensitive data like AWS Access Keys in a pipeline, and how do you prevent developers from hardcoding them?"*

**The Professional Answer:**
"I implement a **'Defense-in-Depth'** and **'Shift-Left'** security strategy. First, I use Infrastructure as Code (Terraform) to provision **AWS Secrets Manager** with a `random_password` generator, ensuring production secrets are never known to humans or stored in plain text. Second, I implement a **Git Pre-commit Hook**—a local security scanner on the developer's workstation. This script intercepts the `git commit` command and uses regex to block any files containing patterns like AWS keys (e.g., `AKIA`) before they ever leave the laptop. This makes security proactive and prevents accidental leaks before they reach the remote repository."

---

## 🛠️ 2. Step-by-Step Practical Execution

### Phase A: Infrastructure Setup (The Vault)
We create a secure cloud vault to store generated credentials.

**1. File Creation:**
- **Action:** Create `secrets.tf` in the `phase-1-infrastructure` folder.
- **Content:**
```hcl
# Generate a random 16-character secure password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Define the vault in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/rds/mysql-admin-password"
  description             = "Production Database Administrator Password"
  recovery_window_in_days = 7
}

# Inject the generated password into the vault version
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}
2. Terminal Commands to Deploy:Bashterraform init
terraform apply
Phase B: Local Security Automation (The Hook)We build a script to act as a "Gatekeeper" on the local machine.1. Setup the Script:Action: Navigate to the hidden hooks directory: cd .git/hooksAction: Create and edit the file: nano pre-commitContent:Bash#!/bin/bash
# Patterns to block: AWS Access Keys (AK-IA) and 'password=' assignments
BLOCKED_PATTERNS="(AKIA[0-9A-Z]{16}|password\s*=\s*['\"].+['\"])"

echo "🛡️ DevSecOps Scanner: Running security check..."

FILES_TO_COMMIT=$(git diff --cached --name-only)

for FILE in $FILES_TO_COMMIT; do
    if grep -qE "$BLOCKED_PATTERNS" "$FILE"; then
        echo "❌ SECURITY ALERT: Secret detected in: $FILE"
        echo "❌ Commit rejected! Remove the secret and use AWS Secrets Manager."
        exit 1 # Abort the commit
    fi
done
exit 0
2. Activate the Scanner:Bashchmod +x pre-commit
cd ../..
🧪 3. Validation and Testing (Proof of Concept)The Failure Test (Simulating an Error)Create a dummy secret file:echo 'aws_key="AKIAIOSFODNN7EXAMPLE"' > test-secret.txtAttempt to commit:git add test-secret.txtgit commit -m "Testing security hook"Result: The terminal output shows: ❌ SECURITY ALERT: Secret detected... and the commit fails.The CleanupRemove the bad file: rm test-secret.txtClear Git's memory: git reset🚀 4. Final Deployment to GitHubTo push the documentation snippets containing example "AKIA" strings, we use the professional bypass flag.Terminal Commands:Bash# Navigate to the correct folder
cd phase-1-infrastructure

# Stage the finished files
git add secrets.tf
git add SCENARIO-3-SECURITY.md

# Commit using the bypass flag for documentation
git commit -m "docs: finalize master source for Scenario 3" --no-verify

# Push to GitHub
git push origin main
💡 5. Master Command GlossaryCommandWhy We Used ItnanoTerminal text editor used to create the config and scripts.terraform initInitialized the AWS and Random providers for the vault.chmod +xConverted the text script into a running automation tool.git resetCleared the 'ghost' secret from Git memory after the block.--no-verifyAllowed the documentation to pass despite containing sample strings.