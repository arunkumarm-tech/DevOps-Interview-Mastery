# The Default Provider (US-East-1)
provider "aws" {
  region = "us-east-1"
}

# The Ireland Alias
provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}
