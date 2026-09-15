locals {
  regional_prefix = "${var.environment}-${var.project_name}"
  global_prefix   = "${var.environment}-${data.aws_region.current.region}-${var.project_name}"
  ssm_prefix      = "${var.environment}/${data.aws_region.current.region}/${var.project_name}"
}
