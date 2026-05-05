terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    bucket         = "eks-node-app-project-tf-bucket"
    key            = "eks/terraform.tfstate"
    region         = "us-east-1"
  }
}


provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = var.managed_by
      Project     = var.project
      Author       = var.author
    }
  }
}

module "networks" {
  source = "../../modules/networks"

  vpc_cidr_block = var.vpc_cidr_block
  environment    = var.environment
  public_subnet_cidr_block_1  = var.public_subnet_cidr_block_1
  public_subnet_cidr_block_2  = var.public_subnet_cidr_block_2
  private_subnet_cidr_block_1 = var.private_subnet_cidr_block_1
  private_subnet_cidr_block_2 = var.private_subnet_cidr_block_2
  availability_zones           = var.availability_zones
}

module "iam" {
  source = "../../modules/iam"

  environment    = var.environment
}

module "eks" {
  source = "../../modules/eks"

  cluster_name   = var.cluster_name
  environment    = var.environment
  eks_cluster_role_arn = module.iam.iam_role_arn
  kubernetes_version = var.kubernetes_version
  public_subnet_ids  = module.networks.public_subnet_ids
  private_subnet_ids = module.networks.private_subnet_ids

  # nodegroup configuration
  eks_nodegroup_role_arn = module.iam.nodegroup_role_arn
  node_group_desired_size = var.node_group_desired_size
  node_group_max_size = var.node_group_max_size
  node_group_min_size = var.node_group_min_size
  node_group_capacity_type = var.node_group_capacity_type
  node_group_instance_types = var.node_group_instance_types
  node_group_disk_size = var.node_group_disk_size
  node_group_max_unavailable = var.node_group_max_unavailable

  depends_on = [module.networks]
}

module "eks-access" {
  source = "../../modules/eks-access"

  admin_principal_arns = var.admin_principal_arns
  cluster_name = module.eks.cluster_name

  depends_on = [module.eks]
}
