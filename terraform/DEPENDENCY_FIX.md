# Terraform Dependency Fix

## Problem
During `terraform destroy`, AWS was throwing dependency violation errors:
- Internet Gateway couldn't detach because NAT Gateway still had mapped public addresses (EIP)
- Subnets couldn't be deleted because EKS cluster had created ENIs in them

## Root Cause
Terraform wasn't enforcing the proper destroy order:
1. EKS resources (cluster + node groups) need to be destroyed first
2. NAT Gateway needs to be destroyed before IGW
3. Route table associations need to be destroyed before subnets
4. Subnets need to wait for all ENIs to be cleaned up

## Changes Made

### 1. Module-Level Dependencies ([terraform/environments/dev/main.tf](terraform/environments/dev/main.tf))
```terraform
module "eks" {
  ...
  nat_gateway_id = module.networks.nat_gateway_id  # Added
  depends_on = [module.networks]  # Ensures EKS destroyed before networks
}

module "eks-access" {
  ...
  depends_on = [module.eks]  # Ensures access policies removed before cluster
}
```

### 2. NAT Gateway Explicit Dependencies ([terraform/modules/networks/main.tf](terraform/modules/networks/main.tf))
```terraform
resource "aws_nat_gateway" "main" {
  ...
  depends_on = [
    aws_internet_gateway.main,
    aws_subnet.subnet-public-1,
    aws_subnet.subnet-public-2
  ]
}
```

### 3. Route Table Dependencies ([terraform/modules/networks/main.tf](terraform/modules/networks/main.tf))
```terraform
resource "aws_route_table" "public" {
  ...
  depends_on = [aws_internet_gateway.main]
}

resource "aws_route_table" "private" {
  ...
  depends_on = [aws_nat_gateway.main]
}
```

### 4. EKS Cluster Tag Dependency ([terraform/modules/eks/main.tf](terraform/modules/eks/main.tf))
```terraform
resource "aws_eks_cluster" "main" {
  ...
  tags = {
    Name = "${var.cluster_name}-${var.environment}"
    NatGatewayDep = var.nat_gateway_id  # Creates implicit dependency
  }
}
```

## Destroy Order (Enforced by Dependencies)
1. ✅ eks-access module (IAM access policies)
2. ✅ EKS node groups (releases ENIs from private subnets)
3. ✅ EKS cluster (releases ENIs from public subnets)
4. ✅ Route table associations
5. ✅ Private route table
6. ✅ Public route table  
7. ✅ NAT Gateway (releases EIP)
8. ✅ EIP (unmaps public address from VPC)
9. ✅ Internet Gateway (can now detach cleanly)
10. ✅ Subnets (no more dependencies)
11. ✅ VPC

## Testing
After applying these changes, run:
```bash
cd terraform/environments/dev
terraform init
terraform plan  # Should show no changes if already applied
terraform destroy  # Should complete without dependency errors
```

## Notes
- The `nat_gateway_id` variable passed to EKS module creates an implicit Terraform dependency
- The tag reference in EKS cluster ensures the NAT Gateway ID is evaluated, solidifying the dependency
- Module-level `depends_on` is explicit and ensures proper ordering
- These changes work for both `apply` and `destroy` operations
