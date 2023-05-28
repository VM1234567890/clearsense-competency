# Account
region = "us-east-1"

# Network.tf

vpc_cidr_block = "10.0.0.0/16"
vpc_name       = "web_vpc"

subnet_cidr_block = "10.0.1.0/24"
subnet_name       = "web-subnet-a"

public_subnet_cidr_block = "10.0.2.0/24"
db_subnet1_cidr_block    = "10.0.11.0/24"
db_subnet2_cidr_block    = "10.0.12.0/24"


sg_name        = "web-security-group"
sg_description = "security group for the web instences"

# Compute

aws_ami_value = "al2023-ami-2023.*-x86_64"
instance_type = "t2.micro"
instance_name = "web-instance"
key_name      = "web_key"

# Database
port = 3306