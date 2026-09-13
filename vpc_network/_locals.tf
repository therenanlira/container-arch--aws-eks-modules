locals {
  regional_prefix = var.environment
  global_prefix   = "${var.environment}-${data.aws_region.current.region}"

  subnet_private_blocks = cidrsubnet(var.cidr_block, 2, 0)
  subnet_public_blocks  = cidrsubnet(var.cidr_block, 2, 1)
  subnet_data_blocks    = cidrsubnet(var.cidr_block, 2, 2)

  vpc_azs = toset(slice(data.aws_availability_zones.available.names, 0, var.subnet_count))

  private_sub_eks_tag = length(var.eks_cidr) > 0 ? {
    "kubernetes.io/role/internal-elb" = "1"
  } : {}

  public_sub_eks_tag = length(var.eks_cidr) > 0 ? {
    "kubernetes.io/role/elb" = "1"
  } : {}
}
