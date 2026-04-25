Step 2: The Command List
As we work through this, these are the commands we will be using. 
terraform init: Initialize providers for both us-east-1 and eu-west-1.

terraform plan: To see the cross-region dependency.

aws ec2 describe-vpc-peering-connections: To verify the status in the CLI.

ping [Private-IP]: To test the actual connection between the US and Ireland.


Scenario 06
Here is the complete, professional README.md content for your Scenario-06-Global-VPC-Peering folder. It includes all the "Senior Level" troubleshooting we did today.


# Scenario 06: Global VPC Peering (US-East-1 to EU-West-1)

## Objective
To establish a secure, low-latency private network connection between two geographically distant AWS regions (N. Virginia and Ireland) using **Global VPC Peering**. This allows resources in different regions to communicate using private IP addresses without traversing the public internet.

## Architecture
* **Region A (US-East-1):** VPC `10.1.0.0/16` | Subnet `10.1.1.0/24`
* **Region B (EU-West-1):** VPC `10.2.0.0/16` | Subnet `10.2.1.0/24`
* **Connection:** VPC Peering with cross-region route table updates.



---

## Phase 1: Infrastructure as Code (Terraform)
The implementation required the use of **Terraform Aliases** to manage providers across two different regions simultaneously.

```hcl
# Cross-Region Peering Request
resource "aws_vpc_peering_connection" "us_to_ireland" {
  vpc_id        = aws_vpc.us_vpc.id
  peer_vpc_id   = aws_vpc.ireland_vpc.id
  peer_region   = "eu-west-1"
  auto_accept   = false
}

# Cross-Region Peering Accepter
resource "aws_vpc_peering_connection_accepter" "ireland_accepter" {
  provider                  = aws.ireland
  vpc_peering_connection_id = aws_vpc_peering_connection.us_to_ireland.id
  auto_accept               = true
}



Phase 3: Final Verification
1. Cross-Region Connectivity
Logged into the US Server (10.1.1.19) and successfully pinged the Ireland Server (10.2.1.204) using its Private IP.

Bash
[ec2-user@ip-10-1-1-19 ~]$ ping 10.2.1.204
PING 10.2.1.204 (10.2.1.204) 56(84) bytes of data.
64 bytes from 10.2.1.204: icmp_seq=1 ttl=255 time=65.7 ms
64 bytes from 10.2.1.204: icmp_seq=2 ttl=255 time=65.8 ms
2. Latency Analysis
The observed latency was consistent at ~65.7ms. This is optimal for transatlantic traffic on the AWS backbone, confirming that the traffic is not being routed through the public internet which would introduce higher jitter and latency.

Conclusion
This lab demonstrates the ability to architect global, multi-region networks while maintaining strict security via private routing and granular Security Group rules.




Scenario 06: Global VPC Peering (N. Virginia ↔ Ireland)
Objective
To architect and implement a secure, private network bridge between two geographically distant AWS regions using Global VPC Peering. This setup ensures that data remains on the AWS global backbone, minimizing latency and maximizing security by avoiding the public internet.

Architecture Overview
Region A (us-east-1): CIDR 10.1.0.0/16 | Subnet 10.1.1.0/24

Region B (eu-west-1): CIDR 10.2.0.0/16 | Subnet 10.2.1.0/24

Connectivity: Bi-directional VPC Peering with automated Route Table updates.

Command Log: Step-by-Step Execution
1. Infrastructure Deployment
Bash
# Initialize providers for multiple AWS regions
terraform init

# Plan the deployment to verify cross-region resources
terraform plan

# Execute the build (VPCs, Peering, Routes, and Instances)
terraform apply -auto-approve
2. Verification (Connectivity Testing)
Bash
# Connect to US Server and Ping Ireland (10.2.x.x)
ping 10.2.1.204

# Connect to Ireland Server and Ping US (10.1.x.x)
ping 10.1.1.19

# Trace the path to ensure it's not leaving the AWS network
traceroute 10.2.1.204


Scenario 06: Global VPC Peering (Cross-Region Connectivity)
Objective
To establish a high-performance, private connection between two AWS regions—N. Virginia (us-east-1) and Ireland (eu-west-1). This architecture allows secure communication between global workloads without exposing traffic to the public internet.

The Command Log
1. Infrastructure Deployment
We used Terraform to handle the complexity of multi-region provider management.

terraform init: Initialized the project, downloading regional providers for both the US and Ireland.

terraform apply -auto-approve: Provisioned the dual VPCs, the peering request, the cross-region acceptance, and the EC2 test instances.

2. Validation Tests
ping 10.2.1.204: Executed from the US server to verify the bridge to Ireland.

ping 10.1.1.19: Executed from the Ireland server to verify bi-directional (return) traffic.

hostname -I: Used on both servers to confirm we were operating strictly within the private IP space (10.1.x.x and 10.2.x.x).

Phase 2: Troubleshooting & Lessons Learned
Issue 1: Regional Data Isolation
Problem: Terraform threw an "undeclared resource" error for the AMI data source.
Cause: AMIs are region-bound. A data source defined for us-east-1 cannot see images in eu-west-1.
Specialist Solution: I implemented separate regional data blocks with specific provider aliases to ensure each region fetched its own native Amazon Linux 2 image.

Issue 2: Network Context Mismatch
Problem: The EC2 launch failed with an "InvalidParameter" error stating the security group and subnet belonged to different networks.
Cause: Without an explicit subnet_id, AWS attempted to launch instances in the "Default VPC," which conflicted with our custom "Peered VPC" security groups.
Specialist Solution: I explicitly mapped each instance to its respective regional subnet ID, ensuring the compute and security layers were perfectly aligned.

Issue 3: Subnet Accessibility (The "Stranded Instance")
Problem: The AWS Console showed a warning: "Instance is not in a public subnet," and SSH connection timed out.
Cause: Even with a Public IP, the subnet lacked an Internet Gateway (IGW) and a default route (0.0.0.0/0) to handle internet traffic.
Specialist Solution: I provisioned an aws_internet_gateway for both VPCs and updated the Route Tables to enable external connectivity for management purposes.

Issue 4: Protocol Misconfiguration (TCP vs. ICMP)
Problem: Initial pings between regions were hanging indefinitely.
Cause: The Security Group was strictly limited to TCP (Port 22) for SSH. However, ping utilizes the ICMP protocol, which was being dropped by the firewall.
Specialist Solution: I added a specific Inbound Rule for All ICMP - IPv4 from the peered VPC CIDR range. This fixed the one-way connection from US to Ireland.

Issue 5: Asymmetrical Security Rules
Problem: Ping worked from US to Ireland, but the reverse (Ireland to US) showed 100% packet loss.
Cause: While the Ireland Security Group was open, the US Security Group lacked an inbound rule for the Ireland network. Because security groups are stateful, they allow replies to requests you started, but block "new" conversations started by the peer.
Specialist Solution: I updated the US Security Group symmetrically to allow inbound ICMP from the Ireland CIDR (10.2.0.0/16).

Success Metrics & Results
Verified Connectivity
Full-mesh, bi-directional connectivity was achieved. Both servers can now communicate across the Atlantic Ocean using private IP addresses.

Latency Performance
Transatlantic Round-Trip: ~65.7ms.

Conclusion: This latency is consistent with the AWS global backbone. Traffic is verified to be bypassing the public internet, providing a secure and stable path for production logs or database replication.

Final Infrastructure State
To maintain cost efficiency and follow DevOps best practices, the environment was decommissioned immediately after verification using:

terraform destroy -auto-approve
