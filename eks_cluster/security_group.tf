# Security Group

resource "aws_vpc_security_group_ingress_rule" "nodeports" {
  description = "Nodeports ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 30000
  to_port     = 32768
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "coredns_udp" {
  description = "Coredns UDP ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 53
  to_port     = 53
  ip_protocol = "udp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "coredns_tcp" {
  description = "Coredns TCP ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 53
  to_port     = 53
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "wildcard_80" {
  count = var.enable_namespace_wildcard ? 1 : 0

  description = "Namespace Wildcard HTTP ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "wildcard_443" {
  count = var.enable_namespace_wildcard ? 1 : 0

  description = "Namespace Wildcard HTTPS ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "wildcard_8080" {
  count = var.enable_namespace_wildcard ? 1 : 0

  description = "Namespace Wildcard HTTP 8080 ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 8080
  to_port     = 8080
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "wildcard_8443" {
  count = var.enable_namespace_wildcard ? 1 : 0

  description = "Namespace Wildcard HTTPS 8443 ingress"

  security_group_id = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id

  from_port   = 8443
  to_port     = 8443
  ip_protocol = "tcp"

  cidr_ipv4 = "0.0.0.0/0"
}
