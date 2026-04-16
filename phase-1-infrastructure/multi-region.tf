# 3. Resource in US (Default)
resource "aws_sns_topic" "us_alerts" {
  name = "global-alerts-us"
}

# 4. Resource in Europe (Using the Alias)
resource "aws_sns_topic" "eu_alerts" {
  provider = aws.ireland  # This tells Terraform to use the Ireland alias
  name     = "global-alerts-eu"
}