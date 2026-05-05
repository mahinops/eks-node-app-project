variable "admin_principal_arns" {
  description = "List of IAM principal ARNs to be granted admin access to the EKS cluster"
  type        = list(string)
  default     = []
}

variable "cluster_name" {
  description = "The name of the EKS cluster to associate access with"
  type        = string
  default     = ""
}