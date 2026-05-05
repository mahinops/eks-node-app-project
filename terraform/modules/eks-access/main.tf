resource "aws_eks_access_entry" "eks-admin-access" {
  for_each = toset(var.admin_principal_arns)

  cluster_name = var.cluster_name
  principal_arn = each.value
  type = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks-admin-policy" {
  for_each = toset(var.admin_principal_arns)

  cluster_name  = var.cluster_name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = each.value

  access_scope {
    type       = "cluster"
  }

  depends_on = [ aws_eks_access_entry.eks-admin-access ]
}