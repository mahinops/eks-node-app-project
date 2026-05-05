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

# eks 
cluster_name = "tf-eks-cluster"
kubernetes_version = "1.33"

# eks nodegroup  

node_group_desired_size = 2
node_group_max_size = 3
node_group_min_size = 1
node_group_capacity_type = "ON_DEMAND"
node_group_instance_types = ["t3.small"]
node_group_disk_size = 20
node_group_max_unavailable = 1


# eks-access 
admin_principal_arns = [
    "arn:aws:iam::922344941106:user/mahin",
    "arn:aws:iam::922344941106:role/github-actions-role",
]