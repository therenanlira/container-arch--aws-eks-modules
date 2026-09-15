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
