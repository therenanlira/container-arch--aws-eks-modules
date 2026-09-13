# Private and Data Route Tables

resource "aws_route_table" "private" {
  for_each = local.vpc_azs

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.regional_prefix}-private-rt-${each.key}"
  }
}

resource "aws_route" "private_internet_access" {
  for_each = local.vpc_azs

  route_table_id         = aws_route_table.private[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.natgw[each.key].id
}

resource "aws_route_table_association" "private_rta" {
  for_each = local.vpc_azs

  subnet_id      = aws_subnet.these_private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "data_rta" {
  for_each = local.vpc_azs

  subnet_id      = aws_subnet.these_data[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_route_table_association" "eks_rta" {
  for_each = length(var.eks_cidr) > 0 ? local.vpc_azs : toset([])

  subnet_id      = aws_subnet.these_eks[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

# Public Route Tables

resource "aws_route_table" "public" {
  for_each = local.vpc_azs

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.regional_prefix}-public-rt-${each.key}"
  }
}

resource "aws_route" "public_internet_access" {
  for_each = local.vpc_azs

  route_table_id         = aws_route_table.public[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

resource "aws_route_table_association" "public_rta" {
  for_each = local.vpc_azs

  subnet_id      = aws_subnet.these_public[each.key].id
  route_table_id = aws_route_table.public[each.key].id
}
