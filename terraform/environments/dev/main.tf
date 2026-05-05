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