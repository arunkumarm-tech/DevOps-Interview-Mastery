# Data Source for US-East-1 (Virginia)
data "aws_ami" "amazon_linux_us" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Data Source for EU-West-1 (Ireland)
data "aws_ami" "amazon_linux_ireland" {
  provider    = aws.ireland  # <--- Critical: Tells Terraform to look in Ireland
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}


# 1. PROVIDERS (We need an 'alias' for the second region)
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "ireland"
  region = "eu-west-1"
}

# 2. VPCs (Using different CIDRs so they don't overlap)
resource "aws_vpc" "us_vpc" {
  cidr_block = "10.1.0.0/16"
  tags       = { Name = "US-VPC" }
}

resource "aws_vpc" "ireland_vpc" {
  provider   = aws.ireland
  cidr_block = "10.2.0.0/16"
  tags       = { Name = "Ireland-VPC" }
}

# 3. THE PEERING REQUEST (From US to Ireland)
resource "aws_vpc_peering_connection" "us_to_ireland" {
  vpc_id        = aws_vpc.us_vpc.id
  peer_vpc_id   = aws_vpc.ireland_vpc.id
  peer_region   = "eu-west-1"
  auto_accept   = false # Must be false for cross-region
}

# 4. THE PEERING ACCEPTER (In Ireland)
resource "aws_vpc_peering_connection_accepter" "ireland_accepter" {
  provider                  = aws.ireland
  vpc_peering_connection_id = aws_vpc_peering_connection.us_to_ireland.id
  auto_accept               = true
}

# 5. ROUTE: US to Ireland (Go to 10.2.x.x via Peering ID)
resource "aws_route" "us_to_ireland_route" {
  route_table_id            = aws_vpc.us_vpc.main_route_table_id
  destination_cidr_block    = aws_vpc.ireland_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.us_to_ireland.id
}

# 6. ROUTE: Ireland to US (Go to 10.1.x.x via Peering ID)
resource "aws_route" "ireland_to_us_route" {
  provider                  = aws.ireland
  route_table_id            = aws_vpc.ireland_vpc.main_route_table_id
  destination_cidr_block    = aws_vpc.us_vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.us_to_ireland.id
}


# 1. Security Group for US Instance (Allow Ping from Ireland)

resource "aws_security_group" "us_sg" {
  name   = "us-allow-ping"
  vpc_id = aws_vpc.us_vpc.id

  # 1. Allow SSH (Existing)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # 2. Allow ICMP (THE MISSING PIECE)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["10.2.0.0/16"] # Allow Ireland CIDR to Ping US
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}




# 2. Security Group for Ireland Instance (Allow Ping from US)

resource "aws_security_group" "ireland_sg" {
  provider = aws.ireland
  vpc_id   = aws_vpc.ireland_vpc.id

  # Rule 1: Allow SSH (TCP) - So you can log in
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Rule 2: Allow PING (ICMP) - So the US can reach it
  ingress {
    from_port   = -1            # -1 means "All" for ICMP
    to_port     = -1            # -1 means "All" for ICMP
    protocol    = "icmp"        # <--- This is the missing piece!
    cidr_blocks = ["10.1.0.0/16"] # Only allow from your US VPC
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 3. Test Instances

# US Instance
resource "aws_instance" "us_server" {
  ami                         = data.aws_ami.amazon_linux_us.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.us_subnet.id # <--- Connect to the right network
  vpc_security_group_ids      = [aws_security_group.us_sg.id]
  associate_public_ip_address = true 

  tags = { Name = "US-Server-10.1" }
}

# Ireland Instance
resource "aws_instance" "ireland_server" {
  provider                    = aws.ireland
  ami                         = data.aws_ami.amazon_linux_ireland.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.ireland_subnet.id # <--- Connect to the right network
  vpc_security_group_ids      = [aws_security_group.ireland_sg.id]
  associate_public_ip_address = true

  tags = { Name = "Ireland-Server-10.2" }
}



# 1. Create Subnet in US VPC
resource "aws_subnet" "us_subnet" {
  vpc_id            = aws_vpc.us_vpc.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags              = { Name = "US-Subnet" }
}

# 2. Create Subnet in Ireland VPC
resource "aws_subnet" "ireland_subnet" {
  provider          = aws.ireland
  vpc_id            = aws_vpc.ireland_vpc.id
  cidr_block        = "10.2.1.0/24"
  availability_zone = "eu-west-1a"
  tags              = { Name = "Ireland-Subnet" }
}

# US Internet Gateway
resource "aws_internet_gateway" "us_igw" {
  vpc_id = aws_vpc.us_vpc.id
  tags   = { Name = "US-IGW" }
}

# Ireland Internet Gateway
resource "aws_internet_gateway" "ireland_igw" {
  provider = aws.ireland
  vpc_id   = aws_vpc.ireland_vpc.id
  tags     = { Name = "Ireland-IGW" }
}



# Route US Subnet to US IGW
resource "aws_route" "us_internet_route" {
  route_table_id         = aws_vpc.us_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.us_igw.id
}

# Route Ireland Subnet to Ireland IGW
resource "aws_route" "ireland_internet_route" {
  provider               = aws.ireland
  route_table_id         = aws_vpc.ireland_vpc.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ireland_igw.id
}


