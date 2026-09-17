# Termination - IAM

data "aws_iam_policy_document" "node_termination" {
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

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:kube-system:aws-node-termination-handler"
      ]
    }
  }
}

data "aws_iam_policy_document" "node_termination_policy" {
  version = "2012-10-17"

  statement {

    effect = "Allow"
    actions = [
      "autoscaling:CompleteLifecycleAction",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeTags",
      "ec2:DescribeInstances",
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]

    resources = [
      "*"
    ]
  }
}

resource "aws_iam_role" "node_termination" {
  name               = "${local.global_prefix}-node-termination"
  assume_role_policy = data.aws_iam_policy_document.node_termination.json
}

resource "aws_iam_policy" "node_termination_policy" {
  name        = "${local.global_prefix}-node-termination"
  path        = "/"
  description = var.project_name

  policy = data.aws_iam_policy_document.node_termination_policy.json
}

resource "aws_iam_policy_attachment" "aws_iam_policy_document" {

  name = "aws_node_termination_handler"
  roles = [
    aws_iam_role.node_termination.name
  ]

  policy_arn = aws_iam_policy.node_termination_policy.arn
}

# Termination - SQS

resource "aws_sqs_queue" "node_termination" {
  name                       = "${local.global_prefix}-node-termination"
  delay_seconds              = 0
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
  visibility_timeout_seconds = 60
}

data "aws_iam_policy_document" "node_termination_queue" {
  statement {
    actions   = ["sqs:SendMessage"]
    resources = [aws_sqs_queue.node_termination.arn]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com", "sqs.amazonaws.com"]
    }
  }
}

resource "aws_sqs_queue_policy" "node_termination" {
  queue_url = aws_sqs_queue.node_termination.id
  policy    = data.aws_iam_policy_document.node_termination_queue.json
}

# Termination - EventBridge

locals {
  node_termination_events = {
    instance-terminate = {
      source      = ["aws.autoscaling"]
      detail-type = ["EC2 Instance-terminate Lifecycle Action"]
    }
    scheduled-change = {
      source      = ["aws.health"]
      detail-type = ["AWS Health Event"]
      detail = {
        service           = ["EC2"]
        eventTypeCategory = ["scheduledChange"]
      }
    }
    spot-termination = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Spot Instance Interruption Warning"]
    }
    rebalance = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance Rebalance Recommendation"]
    }
    state-change = {
      source      = ["aws.ec2"]
      detail-type = ["EC2 Instance State-change Notification"]
    }
  }
}

resource "aws_cloudwatch_event_rule" "node_termination" {
  for_each = local.node_termination_events

  name          = "${local.global_prefix}-node-${each.key}"
  description   = var.project_name
  event_pattern = jsonencode(each.value)
}

resource "aws_cloudwatch_event_target" "node_termination" {
  for_each = aws_cloudwatch_event_rule.node_termination

  rule      = each.value.name
  target_id = "SendToSQS"
  arn       = aws_sqs_queue.node_termination.arn
}

# Termination - Helm

resource "helm_release" "node_termination_handler" {
  name      = "aws-node-termination-handler"
  namespace = "kube-system"

  chart      = "aws-node-termination-handler"
  repository = "https://aws.github.io/eks-charts/"

  set = [
    {
      name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
      value = aws_iam_role.node_termination.arn
    },
    {
      name  = "awsRegion"
      value = data.aws_region.current.id
    },
    {
      name  = "queueURL"
      value = aws_sqs_queue.node_termination.url
    },
    {
      name  = "enableSqsTerminationDraining"
      value = true
    },
    {
      name  = "enableSpotInterruptionDraining"
      value = true
    },
    {
      name  = "enableRebalanceMonitoring"
      value = true
    },
    {
      name  = "enableRebalanceDraining"
      value = true
    },
    {
      name  = "enableScheduledEventDraining"
      value = true
    },
    {
      name  = "deleteSqsMsgIfNodeNotFound"
      value = true
    },
    {
      name  = "checkTagBeforeDraining"
      value = false
    }
  ]
}
