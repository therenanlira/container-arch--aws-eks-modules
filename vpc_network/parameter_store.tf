# SSM Parameter Store

resource "aws_ssm_parameter" "vpc" {
  name = "/${local.regional_prefix}/vpc"
  type = "String"

  insecure_value = jsonencode({
    vpc_id                  = aws_vpc.main.id
    public_subnet_ids       = { for az in local.vpc_azs : az => aws_subnet.these_public[az].id }
    private_subnet_ids      = { for az in local.vpc_azs : az => aws_subnet.these_private[az].id }
    data_subnet_ids         = { for az in local.vpc_azs : az => aws_subnet.these_data[az].id }
    eks_subnet_ids          = { for az, subnet in aws_subnet.these_eks : az => subnet.id }
    public_route_table_ids  = { for az in local.vpc_azs : az => aws_route_table.public[az].id }
    private_route_table_ids = { for az in local.vpc_azs : az => aws_route_table.private[az].id }
  })
}
