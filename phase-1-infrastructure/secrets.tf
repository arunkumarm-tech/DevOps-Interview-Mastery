# 1. Generate a random, secure password
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# 2. Create the Vault (The Secret inside AWS Secrets Manager)
resource "aws_secretsmanager_secret" "db_credentials" {
  name                    = "prod/rds/mysql-admin-password"
  description             = "Production Database Administrator Password"
  recovery_window_in_days = 7 # Allows recovery if accidentally deleted
}

# 3. Store the generated password securely inside the Vault
resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id     = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.db_password.result
  })
}
