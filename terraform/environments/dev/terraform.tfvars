# Terraform variables
aws_region = "us-east-1"
environment = "dev"
managed_by = "terraform"
project = "tf-workspace-aws-eks"
author = "Mokhlesur Mahin"

# VPC Configuration
vpc_cidr_block = "10.1.0.0/16"

# Subnets Configuration
public_subnet_cidr_block_1 = "10.1.1.0/24"
public_subnet_cidr_block_2 = "10.1.2.0/24"
private_subnet_cidr_block_1 = "10.1.3.0/24"
private_subnet_cidr_block_2 = "10.1.4.0/24"
availability_zones = ["us-east-1a", "us-east-1b"]
