Scenario 3: CI/CD Pipeline Security & Secret Management (MASTER GUIDE)
🎯 Objective
To engineer a professional "Shift-Left" security framework. We are moving security away from "detecting leaks in the cloud" to "preventing leaks on the laptop" using AWS Secrets Manager and Git Automation.

🎙️ The Interviewer Response (The "Senior Specialist" Narrative)
Question: "How do you securely manage sensitive data like AWS Access Keys or database passwords within a CI/CD pipeline, and how do you prevent developers from hardcoding them?"

My Response:
"In my approach, I implement a Defense-in-Depth strategy focused on two pillars:

Dynamic Secrets with Zero-Human Knowledge: Instead of hardcoding credentials, I use Terraform to provision AWS Secrets Manager. I use the random_password provider to generate a 16-character, high-entropy password at runtime. This password is injected directly into the vault. This ensures the password never exists in a developer's head or a text file.

Automated Pre-Commit Blocking: To stop human error before it reaches the cloud, I develop custom Git Pre-commit Hooks. This script lives in the .git/hooks directory and intercepts every git commit command. It uses regex to scan staged files for AWS Access Keys (AKIA) or hardcoded password strings. If a secret is detected, the commit is physically blocked and rejected locally.

This combined approach ensures we don't just 'monitor' for leaks; we 'engineer' them out of existence."

🛠️ Step 1: The Infrastructure (AWS Secrets Manager)
We use Terraform to build a secure vault that generates its own secret.

File Location: phase-1-infrastructure/secrets.tf
The Code:

Terraform
# 1. Generate a secure, random password (16 characters)
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Define the Secret metadata in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/rds/mysql-admin-password"
  description             = "Production Database Administrator Password"
  recovery_window_in_days = 7 # Protection against accidental deletion
}

# 3. Store the generated password inside the Secret version
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}
Commands to Execute:

terraform init (Downloads the random and aws providers)

terraform apply (Deploys the vault to account 160827082645)

🛡️ Step 2: The Security Scanner (Git Hook Script)
We build a script to act as a "Gatekeeper" on your MacBook Air.

File Location: .git/hooks/pre-commit (Hidden directory)
The Script:

Bash
#!/bin/bash

# 1. Define the 'Red Flag' patterns
# This catches AWS Access Keys and common hardcoded password formats
BLOCKED_PATTERNS="(AKIA[0-9A-Z]{16}|password\s*=\s*['\"].+['\"])"

echo "🛡️ DevSecOps Scanner: Running local security audit..."

# 2. Get list of files that are about to be committed
FILES_TO_COMMIT=$(git diff --cached --name-only)

for FILE in $FILES_TO_COMMIT; do
    # 3. Scan each file for secrets
    if grep -qE "$BLOCKED_PATTERNS" "$FILE"; then
        echo "❌ SECURITY ALERT: A secret was detected in: $FILE"
        echo "❌ COMMIT REJECTED! Remove the secret and use Secrets Manager."
        exit 1 # This kills the commit process immediately
    fi
done

echo "✅ Security check passed. Proceeding with commit."
exit 0
Commands to Execute:

cd .git/hooks

nano pre-commit (Paste the script and save)

chmod +x pre-commit (This makes the script "Executable" so it can run)

cd ../.. (Return to your project root)

🧪 Step 3: The Validation (Testing the Defense)
We must prove to ourselves that the scanner works.

Create a 'Bad' File:

echo 'aws_key="AKIAIOSFODNN7EXAMPLE"' > test-secret.txt

Try to Commit:

git add test-secret.txt

git commit -m "testing scanner"

The Result: The terminal should print the ❌ SECURITY ALERT and stop the commit.

🧹 Step 4: Cleanup & Staging (Final Commit)
Once the test passes, we clean up the "ghost" files and commit the real work.

Commands to Execute:

rm test-secret.txt (Delete the fake secret)

git reset (Clear Git's memory of the fake secret)

git add phase-1-infrastructure/secrets.tf

git add phase-1-infrastructure/SCENARIO-3-SECURITY.md

git commit -m "feat: implemented Secrets Manager and Git pre-commit security hooks"

git push origin main

💡 Key Technical Takeaways for HCL Tech Interviews
Shift-Left: Catching errors at the laptop level is faster and cheaper than catching them in Jenkins/GitHub.

Zero-Knowledge: By using random_password, the admin doesn't even know the password, preventing insider threats.

Automation: Using chmod +x on hooks ensures that security is enforced every single time without human intervention.