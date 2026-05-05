variable "aws_region" {
  description = "AWS region to deploy resources in"
  type        = string
  default     = ""
  
}

variable "environment" {
  description = "The environment to deploy to"
  type        = string
  default     = ""
}

variable "managed_by" {
  description = "The tool managing the resources"
  type        = string
  default     = ""
  
}

variable "project" {
  description = "The name of the project"
  type        = string
  default     = ""
}

variable "author" {
  description = "The author of the resources"
  type        = string
  default     = ""
}


variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "public_subnet_cidr_block_1" {
  description = "CIDR block for the first public subnet"
  type        = string
  default     = ""
}

variable "public_subnet_cidr_block_2" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = ""
}

variable "private_subnet_cidr_block_1" {
  description = "CIDR block for the first private subnet"
  type        = string
  default     = ""
}

variable "private_subnet_cidr_block_2" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = ""
}

variable "availability_zones" {
  description = "Availability zones for the subnets"
  type        = list(string)
  default     = []
}


# eks 

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

# eks nodegroup 

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

variable "node_group_max_unavailable" {
  description = "The maximum number of unavailable nodes during an update"
  type        = number
  default     = 0
  
}

# eks-access 
variable "admin_principal_arns" {
  description = "List of IAM principal ARNs to be granted admin access to the EKS cluster"
  type        = list(string)
  default     = []
}
