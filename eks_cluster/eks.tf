# EKS

resource "aws_eks_cluster" "main" {
  name     = "${local.regional_prefix}-eks"
  version  = var.k8s_version
  role_arn = aws_iam_role.eks_cluster.arn

  vpc_config {
    subnet_ids = [for k, v in var.vpc_network.private_subnet_ids : v]

    # Com o endpoint público restrito, os nodes precisam do privado para
    # falar com a API sem sair pelo NAT.
    endpoint_private_access = true
    endpoint_public_access  = true
    public_access_cidrs     = var.public_access_cidrs
  }

  encryption_config {
    provider {
      key_arn = aws_kms_key.main.arn
    }

    resources = ["secrets"]
  }

  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  zonal_shift_config {
    enabled = true
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  tags = {
    Name                                       = "${local.regional_prefix}-eks",
    "kubernetes.iocluster/${var.project_name}" = "shared"
  }
}
