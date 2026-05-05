# vpc outputs 

output "vpc_id" {
  value = module.networks.vpc_id
}

output "vpc_cidr_block" {
  value = module.networks.vpc_cidr_block
}

output "public_subnet_ids" {
  value = module.networks.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networks.private_subnet_ids
}

output "internet_gateway_id" {
  value = module.networks.internet_gateway_id
}

output "nat_gateway_id" {
  value = module.networks.nat_gateway_id
}

output "public_route_table_id" {
  value = module.networks.public_route_table_id
}

output "private_route_table_id" {
  value = module.networks.private_route_table_id
}

# iam outputs

output "iam_role_name" {
  value = module.iam.iam_role_name
}

output "iam_role_arn" {
  value = module.iam.iam_role_arn
}

output "nodegroup_role_name" {
  value = module.iam.nodegroup_role_name
}

output "nodegroup_role_arn" {
  value = module.iam.nodegroup_role_arn
}

# eks 

output "eks_cluster_id" {
  value = module.eks.eks_cluster_id
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority" {
  value = module.eks.cluster_certificate_authority
}

output "cluster_arn" {
  value = module.eks.cluster_arn
}

