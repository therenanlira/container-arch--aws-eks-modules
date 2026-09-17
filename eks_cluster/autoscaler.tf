# Autoscaler - IAM

data "aws_iam_policy_document" "node_autoscaler" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type = "Federated"
      identifiers = [
        aws_iam_openid_connect_provider.eks.arn
      ]
    }
  }
}

data "aws_iam_policy_document" "autoscaler_policy" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    actions = [
      "autoscaling-plans:DescribeScalingPlans",
      "autoscaling-plans:GetScalingPlanResourceForecastData",
      "autoscaling-plans:DescribeScalingPlanResources",
      "autoscaling:DescribeAutoScalingNotificationTypes",
      "autoscaling:DescribeLifecycleHookTypes",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTerminationPolicyTypes",
      "autoscaling:DescribeScalingProcessTypes",
      "autoscaling:DescribePolicies",
      "autoscaling:DescribeTags",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeMetricCollectionTypes",
      "autoscaling:DescribeLoadBalancers",
      "autoscaling:DescribeLifecycleHooks",
      "autoscaling:DescribeAdjustmentTypes",
      "autoscaling:DescribeScalingActivities",
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAccountLimits",
      "autoscaling:DescribeScheduledActions",
      "autoscaling:DescribeLoadBalancerTargetGroups",
      "autoscaling:DescribeNotificationConfigurations",
      "autoscaling:DescribeInstanceRefreshes",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "autoscaler" {
  name               = "${local.global_prefix}-autoscaler"
  assume_role_policy = data.aws_iam_policy_document.node_autoscaler.json
}

resource "aws_iam_policy" "autoscaler" {
  name   = "${local.global_prefix}-autoscaler"
  path   = "/"
  policy = data.aws_iam_policy_document.autoscaler_policy.json
}

resource "aws_iam_policy_attachment" "autoscaler" {
  name       = "${local.global_prefix}-autoscaler"
  policy_arn = aws_iam_policy.autoscaler.arn

  roles = [
    aws_iam_role.autoscaler.name
  ]
}

# Autoscaler - Helm

resource "helm_release" "cluster_autoscaler" {
  for_each = { for node in var.nodes_config : node.name => node }

  repository = "https://kubernetes.github.io/autoscaler"

  chart = "cluster-autoscaler"
  name  = "aws-cluster-autoscaler"

  namespace        = "kube-system"
  create_namespace = true

  set = [
    {
      name  = "replicaCount"
      value = 1
    },
    {
      name  = "awsRegion"
      value = data.aws_region.current.region
    },
    {
      name  = "rbac.serviceAccount.create"
      value = true
    },
    {
      name  = "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.autoscaler.arn
    },
    {
      name  = "autoscalingGroups[0].name"
      value = aws_eks_node_group.these[each.key].resources[0].autoscaling_groups[0].name
    },
    {
      name  = "autoscalingGroups[0].maxSize"
      value = lookup(var.auto_scale_options, "max")
    },
    {
      name  = "autoscalingGroups[0].minSize"
      value = lookup(var.auto_scale_options, "min")
    }
  ]

  depends_on = [
    aws_eks_cluster.main,
    aws_eks_node_group.these,
  ]
}
