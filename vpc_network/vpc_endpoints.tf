# VPC Gateway Endpoints

resource "aws_vpc_endpoint" "these" {
  for_each = toset(var.vpce_gateways)

  vpc_id            = aws_vpc.main.id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  route_table_ids   = [for rt in aws_route_table.private : rt.id]

  tags = {
    Name = "${local.regional_prefix}-vpce-${each.key}"
  }
}
