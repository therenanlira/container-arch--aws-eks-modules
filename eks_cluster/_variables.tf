# General

variable "project_name" {
  description = "The name of the project, used for tagging and naming resources."
  type        = string
}

variable "environment" {
  description = "The deployment environment (e.g., 'dev', 'staging', 'prod')."
  type        = string
}

# VPC

variable "vpc_network" {
  description = "Network IDs published by the vpc_network module (SSM parameter, jsondecoded)."
  type = object({
    vpc_id             = string
    private_subnet_ids = map(string)
    eks_subnet_ids     = map(string)
  })
}

# EKS

variable "k8s_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.36"
}

variable "public_access_cidrs" {
  description = "CIDRs allowed to reach the public EKS API endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "auto_scale_options" {
  description = "EKS auto scale options."
  type = object({
    min = number
    max = number
    des = number
  })
}

variable "nodes_instance_types" {
  description = "Nodes instance sizes"
  type        = list(string)
}

# Add-ons

variable "addon_cni_version" {
  description = "CNI add-on version "
  type        = string
  default     = "v1.22.4-eksbuild.3"
}

variable "addon_coredns_version" {
  description = "Coredns add-on version "
  type        = string
  default     = "v1.14.3-eksbuild.14"
}

variable "addon_kubeproxy_version" {
  description = "Kube Proxy add-on version "
  type        = string
  default     = "v1.36.0-eksbuild.17"
}
