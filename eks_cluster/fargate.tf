# EKS Fargate - Access Entries

resource "aws_eks_access_entry" "fargate" {
  cluster_name  = aws_eks_cluster.main.id
  principal_arn = aws_iam_role.eks_fargate[0].arn
  type          = "FARGATE_LINUX"
}

# EKS Fargate - EKS Profile

resource "aws_eks_fargate_profile" "these" {
  for_each = toset(var.fargate_services)

  cluster_name         = aws_eks_cluster.main.id
  fargate_profile_name = each.value

  pod_execution_role_arn = aws_iam_role.eks_fargate[0].arn

  subnet_ids = [for k, v in var.vpc_network.eks_subnet_ids : v]

  selector {
    namespace = each.value
  }
}

resource "aws_eks_fargate_profile" "wildcard" {
  count = var.enable_namespace_wildcard ? 1 : 0

  cluster_name         = aws_eks_cluster.main.id
  fargate_profile_name = "wildcard"

  pod_execution_role_arn = aws_iam_role.eks_fargate[0].arn

  subnet_ids = [for k, v in var.vpc_network.eks_subnet_ids : v]

  selector {
    namespace = "*"
  }
}
