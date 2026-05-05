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