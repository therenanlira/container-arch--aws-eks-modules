# KMS Key

resource "aws_kms_key" "main" {
  description = "${local.global_prefix}-kms"

  tags = {
    Name = "${local.global_prefix}-kms"
  }
}

resource "aws_kms_alias" "main" {
  name          = "alias/${local.global_prefix}-kms"
  target_key_id = aws_kms_key.main.id
}
