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