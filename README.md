# eks-node-app-project

A Node.js application deployed on AWS EKS, fully provisioned with Terraform and automated via GitHub Actions.

## Stack

- **App**: Node.js (Express) on port 3000, containerized with Docker
- **Infrastructure**: Terraform modules for VPC, subnets (public/private across 2 AZs), IGW, NAT Gateway, IAM roles, EKS cluster, and node groups
- **Deployment**: Helm chart + Helmfile with HPA (1–20 replicas), LoadBalancer service, deployed to EKS
- **CI/CD**: GitHub Actions pipelines for Terraform apply/destroy, Docker build & push to Docker Hub, and Helmfile deploy to EKS
- **State**: Terraform remote backend on S3
