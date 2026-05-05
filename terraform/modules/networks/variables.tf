variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
  default     = ""
}

variable "environment" {
  description = "The environment to deploy to"
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
