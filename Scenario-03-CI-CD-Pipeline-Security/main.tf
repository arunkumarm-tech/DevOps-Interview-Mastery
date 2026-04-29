# main.tf

provider "aws" {
  region = "us-east-1"
}

# 1. Create the Secret in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name        = "prod/app/db_password"
  description = "Production database password for the application"
}

# 2. Store the actual secret value (In a real scenario, use variables or tfvars)
resource "aws_secretsmanager_secret_version" "db_password_value" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = "admin"
    password = "SuperSecretPassword123!"
  })
}

# 3. Create an IAM Policy allowing read access to this specific secret
resource "aws_iam_policy" "secret_read_policy" {
  name        = "JenkinsSecretReadPolicy"
  description = "Allows Jenkins to read the prod DB password"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db_password.arn
      }
    ]
  })
}

# 4. Create an IAM Role for the Jenkins EC2 Server
resource "aws_iam_role" "jenkins_role" {
  name = "jenkins_ec2_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# 5. Attach the Policy to the Role
resource "aws_iam_role_policy_attachment" "jenkins_secret_attach" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = aws_iam_policy.secret_read_policy.arn
}

# 6. Create the Instance Profile to attach to the EC2 instance
resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins_instance_profile"
  role = aws_iam_role.jenkins_role.name
}



# --- ADD THIS TO YOUR EXISTING main.tf ---

# 7. Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 8. Security Group for Jenkins
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Allow port 8080 for Jenkins UI and 22 for SSH"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In a real setup, restrict this to your IP
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# 9. The Jenkins EC2 Instance
resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id

  # --- UPDATE THIS LINE ---
  instance_type          = "t3.micro" 

  iam_instance_profile   = aws_iam_instance_profile.jenkins_profile.name 
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]

  # Install Java and Jenkins automatically on boot

user_data = <<-EOF
              #!/bin/bash
              sudo dnf update -y
              # Install Java 21 and fontconfig
              sudo dnf install fontconfig java-21-amazon-corretto -y
              # Add Jenkins Repository
              sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
              sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
              
              # Install Jenkins
              sudo dnf install jenkins -y
              
              sudo systemctl daemon-reload
              sudo systemctl enable jenkins
              sudo systemctl start jenkins
              EOF

  tags = {
    Name = "Jenkins-Server-Scenario-03"
  }
}


# 10. Output the Jenkins URL so you can easily access it
output "jenkins_url" {
  value       = "http://${aws_instance.jenkins_server.public_dns}:8080"
  description = "Access the Jenkins UI here (Wait 2-3 minutes for installation)"
}
