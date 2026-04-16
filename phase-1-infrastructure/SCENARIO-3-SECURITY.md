# Scenario 3: CI/CD Pipeline Security & Secret Management

## 🎯 Objective
To implement a "Shift-Left" security architecture that proactively prevents credential leakage and establishes a secure lifecycle for infrastructure secrets using AWS-native services.

---

## 🎙️ Interviewer Response
**Question:** *"How do you securely manage sensitive data like AWS Access Keys or database passwords within a CI/CD pipeline, and how do you prevent developers from hardcoding them?"*

**The Strategy:**
"In my professional practice, I treat security as a first-class citizen of the development lifecycle. I implement a two-tiered defense:

1. **Centralized Vaulting:** We eliminate hardcoded credentials by using **AWS Secrets Manager**. I use Terraform to provision the vault and the `random_password` provider to generate high-entropy passwords. This ensures production secrets are never known by humans or stored in plain text.
2. **Automated Blocking:** To prevent human error, I deploy **Git Pre-commit Hooks**. This 'Shift-Left' approach moves security scanning to the developer's local workstation. The script intercepts the commit command and scans for patterns like AWS Keys or password assignments. If a secret is found, the commit is blocked before the code leaves the laptop."

---

## 🛠️ Step-by-Step Technical Execution

### Step 1: Provisioning the Secure Vault
We use Terraform to build a secure location for secrets. This avoids "Click-Ops" and ensures the vault is reproducible.

**File:** `secrets.tf`
```hcl
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/rds/mysql-admin-password"
  description             = "Production Database Administrator Password"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}


Step 2: Creating the Local Security Guard
This script acts as the automated "firewall" for the code.

Location: .git/hooks/pre-commit
Script Logic:


#!/bin/bash
# Patterns to block: AWS Access Keys and common password formats
BLOCKED_PATTERNS="(AK-IA[0-9A-Z]{16}|password\s*=\s*['\"].+['\"])"

echo "🛡️ DevSecOps Scanner: Running security check..."
FILES_TO_COMMIT=$(git diff --cached --name-only)

for FILE in $FILES_TO_COMMIT; do
    if grep -qE "$BLOCKED_PATTERNS" "$FILE"; then
        echo "❌ SECURITY ALERT: Secret detected in: $FILE"
        exit 1
    fi
done
exit 0


🧪 Testing and Validation
Test Case: The "Accidental Leak"
Action: Created a file leak.txt with a dummy key.

Action: Attempted to commit the file.

Result: The terminal triggered a SECURITY ALERT and the commit failed.