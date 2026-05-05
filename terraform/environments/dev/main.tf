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
