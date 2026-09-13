# Variables
output "project_name" {
  value = var.project_name
}

output "cidr_block" {
  value = var.cidr_block
}

output "subnet_count" {
  value = var.subnet_count
}

output "vpce_gateways" {
  value = var.vpce_gateways
}

output "environment" {
  value = var.environment
}

# Network

output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = { for az in local.vpc_azs : az => aws_subnet.these_public[az].id }
}

output "private_subnet_ids" {
  value = { for az in local.vpc_azs : az => aws_subnet.these_private[az].id }
}

output "data_subnet_ids" {
  value = { for az in local.vpc_azs : az => aws_subnet.these_data[az].id }
}

output "eks_subnet_ids" {
  value = { for az, subnet in aws_subnet.these_eks : az => subnet.id }
}

output "public_route_table_ids" {
  value = { for az in local.vpc_azs : az => aws_route_table.public[az].id }
}

output "private_route_table_ids" {
  value = { for az in local.vpc_azs : az => aws_route_table.private[az].id }
}

# DNS

output "dns_zone_id" {
  value = var.create_dns_zone ? one(aws_route53_zone.private[*].zone_id) : var.dns_zone_id
}

output "dns_name" {
  value = var.create_dns_zone ? one(aws_route53_zone.private[*].name) : var.dns_name
}
