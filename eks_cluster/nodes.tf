# EKS Nodes

resource "aws_eks_node_group" "main" {
  subnet_ids = [for k, v in var.vpc_network.eks_subnet_ids : v]

  cluster_name    = aws_eks_cluster.main.id
  node_group_name = aws_eks_cluster.main.id

  node_role_arn  = aws_iam_role.eks_nodes.arn
  instance_types = var.nodes_instance_types

  scaling_config {
    min_size     = var.auto_scale_options.min
    max_size     = var.auto_scale_options.max
    desired_size = var.auto_scale_options.des
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  labels = {
    "ingress/ready" = "true"
  }

  tags = {
    "kubernetes.iocluster/${var.project_name}" = "owned"
  }

  # depends_on = [
  #   kubernetes_config_map.aws_auth
  # ]

  timeouts {
    create = "1h"
    update = "2h"
    delete = "2h"
  }
}
