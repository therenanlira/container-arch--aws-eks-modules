data "aws_iam_policy_document" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  version = "2012-10-17"

  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  name_prefix        = "${local.regional_prefix}-coredns-fix"
  assume_role_policy = data.aws_iam_policy_document.coredns_fix[0].json
}

resource "aws_iam_role_policy_attachment" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  role       = aws_iam_role.coredns_fix[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_security_group" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  name   = "${local.regional_prefix}-coredns-fix"
  vpc_id = var.vpc_network.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  description = "Fix coredns"

  security_group_id = aws_iam_role.coredns_fix[0].id

  from_port   = 0
  to_port     = 0
  ip_protocol = "-1"

  cidr_ipv4 = "0.0.0.0/0"
}

data "archive_file" "coredns_archive" {
  count = var.enable_coredns_fix ? 1 : 0

  type        = "zip"
  source_file = "${path.cwd}/assets/coredns.py"
  output_path = "${path.cwd}/assets/coredns.zip"
}

resource "aws_lambda_function" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  function_name = "${local.regional_prefix}-coredns-fix"
  runtime       = "python3.13"

  handler          = "main.handler"
  role             = aws_iam_role.coredns_fix[0].arn
  filename         = data.archive_file.coredns_archive[0].output_path
  source_code_hash = data.archive_file.coredns_archive[0].output_base64sha256
  timeout          = 120

  vpc_config {
    subnet_ids         = [for k, v in var.vpc_network.private_subnet_ids : v]
    security_group_ids = [aws_security_group.coredns_fix[0].id]
  }
}

data "aws_eks_cluster_auth" "default" {
  name = aws_eks_cluster.main.name
}

data "aws_lambda_invocation" "coredns_fix" {
  count = var.enable_coredns_fix ? 1 : 0

  function_name = aws_lambda_function.coredns_fix[0].function_name
  input         = <<JSON
    {
      "endpoint": "${aws_eks_cluster.main.endpoint}",
      "token": "${data.aws_eks_cluster_auth.default.token}"
    }
  JSON

  depends_on = [
    aws_lambda_function.coredns_fix[0],
    aws_eks_fargate_profile.wildcard
  ]
}
