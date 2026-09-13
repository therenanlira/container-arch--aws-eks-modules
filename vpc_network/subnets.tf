# Private, Public, Data and EKS Subnets

resource "aws_subnet" "these_private" {
  for_each = local.vpc_azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.subnet_private_blocks, 2, index(data.aws_availability_zones.available.names, each.key))

  tags = merge(local.private_sub_eks_tag, {
    Name = "${local.regional_prefix}-private-subnet-${each.key}"
  })
}

resource "aws_subnet" "these_public" {
  for_each = local.vpc_azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.subnet_public_blocks, 6, index(data.aws_availability_zones.available.names, each.key))

  tags = merge(local.public_sub_eks_tag, {
    Name = "${local.regional_prefix}-public-subnet-${each.key}"
  })
}

resource "aws_subnet" "these_data" {
  for_each = local.vpc_azs

  vpc_id            = aws_vpc.main.id
  availability_zone = each.key
  cidr_block        = cidrsubnet(local.subnet_data_blocks, 4, index(data.aws_availability_zones.available.names, each.key))

  tags = {
    Name = "${local.regional_prefix}-data-subnet-${each.key}"
  }
}

resource "aws_subnet" "these_eks" {
  for_each = length(var.eks_cidr) > 0 ? local.vpc_azs : toset([])

  vpc_id            = aws_vpc_ipv4_cidr_block_association.eks[0].vpc_id
  availability_zone = each.key
  cidr_block        = cidrsubnet(var.eks_cidr, 2, index(data.aws_availability_zones.available.names, each.key))

  tags = {
    Name = "${local.regional_prefix}-eks-subnet-${each.key}"
  }
}
