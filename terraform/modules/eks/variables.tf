variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = ""
}

variable "cluster_name" {
  description = "The name of the EKS cluster"
  type        = string
  default     = ""
  
}

variable "kubernetes_version" {
  description = "The Kubernetes version to use"
  type        = string
  default     = ""
}


variable "public_subnet_ids" {
  description = "The IDs of the public subnets"
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "The IDs of the private subnets"
  type        = list(string)
  default     = []
}

variable "eks_cluster_role_arn" {
  description = "The ARN of the IAM role for the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_nodegroup_role_arn" {
  description = "The ARN of the IAM role for the EKS node group"
  type        = string
  default     = ""
}

variable "node_group_capacity_type" {
  description = "The capacity type for the EKS node group (e.g., ON_DEMAND, SPOT)"
  type        = string
  default     = ""
  
}

variable "node_group_instance_types" {
  description = "The instance types for the EKS node group"
  type        = list(string)
  default     = []
}

variable "node_group_disk_size" {
  description = "The disk size for the EKS node group"
  type        = number
  default     = 0
}

variable "node_group_desired_size" {
  description = "The desired size of the EKS node group"
  type        = number
  default     = 0
}

variable "node_group_max_size" {
  description = "The maximum size of the EKS node group"
  type        = number
  default     = 0
}

variable "node_group_min_size" {
  description = "The minimum size of the EKS node group"
  type        = number
  default     = 0
}

variable "node_group_max_unavailable" {
  description = "The maximum number of unavailable nodes during an update"
  type        = number
  default     = 0
  
}