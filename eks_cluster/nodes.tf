# EKS Nodes

# Default

resource "aws_eks_node_group" "these" {
  for_each = { for node in var.nodes_config : node.name => node }

  subnet_ids = [for k, v in var.vpc_network.eks_subnet_ids : v]

  cluster_name    = aws_eks_cluster.main.id
  node_group_name = "${aws_eks_cluster.main.id}-${each.value.name}"

  node_role_arn  = aws_iam_role.eks_nodes.arn
  instance_types = var.nodes_instance_types
  capacity_type  = each.value.capacity_type
  ami_type       = each.value.ami_type

  scaling_config {
    min_size     = var.auto_scale_options.min
    max_size     = var.auto_scale_options.max
    desired_size = var.auto_scale_options.des
  }

  labels = {
    "capacity/os"   = each.value.capacity_os
    "capacity/arch" = each.value.capacity_arch != null ? each.value.capacity_arch : "x86_64"
    "capacity/type" = each.value.capacity_type
  }

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  tags = {
    "kubernetes.iocluster/${var.project_name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker,
    aws_iam_role_policy_attachment.eks_nodes_cni,
    aws_iam_role_policy_attachment.eks_nodes_ecr
  ]
}

# Custom

resource "aws_launch_template" "custom_node" {
  count = var.custom_node != null ? 1 : 0

  name          = "${local.regional_prefix}-${var.custom_node.name}"
  ebs_optimized = true

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 50
      volume_type = "gp3"
    }
  }

  monitoring {
    enabled = false
  }

  user_data = base64encode(
    templatefile(
      var.custom_node.file_path, {
        CLUSTER_NAME                     = aws_eks_cluster.main.id
        KUBERNETES_ENDPOINT              = aws_eks_cluster.main.endpoint
        KUBERNETES_CERTIFICATE_AUTHORITY = aws_eks_cluster.main.certificate_authority[0].data
      }
    )
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${local.regional_prefix}-${var.custom_node.name}"
    }
  }
}

resource "aws_eks_node_group" "custom_node" {
  count = var.custom_node != null ? 1 : 0

  subnet_ids = [for k, v in var.vpc_network.eks_subnet_ids : v]

  cluster_name    = aws_eks_cluster.main.id
  node_group_name = "${aws_eks_cluster.main.id}-${var.custom_node.name}"

  node_role_arn  = aws_iam_role.eks_nodes.arn
  instance_types = var.nodes_instance_types
  capacity_type  = "ON_DEMAND"

  scaling_config {
    min_size     = var.auto_scale_options.min
    max_size     = var.auto_scale_options.max
    desired_size = var.auto_scale_options.des
  }

  launch_template {
    id      = aws_launch_template.custom_node[0].id
    version = aws_launch_template.custom_node[0].latest_version
  }

  labels = merge({
    "capacity/os"   = "AMAZON_LINUX"
    "capacity/arch" = "x86_64"
    "capacity/type" = "ON_DEMAND"
  })

  lifecycle {
    ignore_changes = [
      scaling_config[0].desired_size
    ]
  }

  tags = {
    "kubernetes.iocluster/${var.project_name}" = "owned"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_nodes_worker,
    aws_iam_role_policy_attachment.eks_nodes_cni,
    aws_iam_role_policy_attachment.eks_nodes_ecr
  ]
}
