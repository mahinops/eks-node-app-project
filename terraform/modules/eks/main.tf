resource "aws_eks_cluster" "main" {
  name     = "${var.cluster_name}-${var.environment}"
  role_arn = var.eks_cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = concat(var.public_subnet_ids, var.private_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = true
  }

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  tags = {
    Name = "${var.cluster_name}-${var.environment}"
  }
}


resource "aws_eks_node_group" "name" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-${var.environment}-node-group"
  node_role_arn   = var.eks_nodegroup_role_arn
  subnet_ids      = var.private_subnet_ids

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  capacity_type = var.node_group_capacity_type
  instance_types = var.node_group_instance_types
  disk_size = var.node_group_disk_size

  update_config {
    max_unavailable = var.node_group_max_unavailable
  }

  tags = {
    Name = "${var.cluster_name}-${var.environment}-node-group"
  }
}