output "iam_role_name" {
  value = aws_iam_role.eks_cluster_role.name
}

output "iam_role_arn" {
  value = aws_iam_role.eks_cluster_role.arn
}

output "nodegroup_role_name" {
  value = aws_iam_role.eks_nodegroup_role.name
}

output "nodegroup_role_arn" {
  value = aws_iam_role.eks_nodegroup_role.arn
}

