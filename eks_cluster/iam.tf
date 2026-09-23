# IAM Roles

## EKS Policies

data "aws_iam_policy_document" "eks_cluster" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "eks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eks_cluster" {
  name               = "${local.global_prefix}-ekscluster-role"
  assume_role_policy = data.aws_iam_policy_document.eks_cluster.json

  tags = {
    Name = "${local.global_prefix}-ekscluster-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_cluster" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

resource "aws_iam_role_policy_attachment" "eks_service" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.eks_cluster.name
}

## Nodes Policies

data "aws_iam_policy_document" "eks_nodes" {
  version = "2012-10-17"

  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eks_nodes" {
  name               = "${local.global_prefix}-eksnodes-role"
  assume_role_policy = data.aws_iam_policy_document.eks_nodes.json

  tags = {
    Name = "${local.global_prefix}-eksnodes-role"
  }
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_cloudwatch" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_role_policy_attachment" "eks_nodes_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_nodes.name
}

resource "aws_iam_instance_profile" "eks_nodes" {
  name = "${local.global_prefix}-eksnodes-instanceprofile"
  role = aws_iam_role.eks_nodes.name
}

data "aws_iam_policy_document" "eks_fargate" {
  count = length(var.fargate_services) > 0 ? 1 : 0

  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type = "Service"
      identifiers = [
        "eks-fargate-pods.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "eks_fargate" {
  count = length(var.fargate_services) > 0 ? 1 : 0

  name               = format("%s-fargate-role", var.project_name)
  assume_role_policy = data.aws_iam_policy_document.eks_fargate[0].json
}

resource "aws_iam_role_policy_attachment" "eks_fargate" {
  count = length(var.fargate_services) > 0 ? 1 : 0

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.eks_fargate[0].name
}
