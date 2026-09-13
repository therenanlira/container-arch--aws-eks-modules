# Route 53 Zone

resource "aws_route53_zone" "private" {
  count = var.create_dns_zone ? 1 : 0

  name = "${var.project_name}.internal.com"

  vpc {
    vpc_id = aws_vpc.main.id
  }

  lifecycle {
    ignore_changes = [vpc]
  }
}

resource "aws_route53_zone_association" "main" {
  count = var.create_dns_zone ? 0 : 1

  zone_id = var.dns_zone_id
  vpc_id  = aws_vpc.main.id
}
