# General

variable "project_name" {
  description = "The name of the project, used for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

# Network

variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "subnet_count" {
  description = "The number of subnets to create in the VPC."
  type        = number
  default     = 3
}

variable "eks_cidr" {
  description = "The CIDR block for the EKS Pods."
  type        = string
  default     = ""
}

variable "vpce_gateways" {
  description = "A list of AWS services for which to create VPC endpoints (e.g., 's3', 'dynamodb')."
  type        = list(string)
  default     = ["s3", "dynamodb"]
}

# DNS

variable "create_dns_zone" {
  description = "Whether to create the private hosted zone. Only the central region creates it; the others associate their VPC to it."
  type        = bool
  default     = true
}

variable "dns_zone_id" {
  description = "Zone ID of the private hosted zone to associate this VPC with. Required when create_dns_zone is false."
  type        = string
  default     = null
  validation {
    condition     = var.create_dns_zone || var.dns_zone_id != null
    error_message = "create_dns_zone = false requires dns_zone_id."
  }
}

variable "dns_name" {
  description = "Name of the private hosted zone when it is not created here."
  type        = string
  default     = null
}

