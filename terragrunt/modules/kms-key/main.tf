resource "aws_kms_key" "this" {
  description         = var.description
  enable_key_rotation = var.enable_key_rotation
  policy              = data.aws_iam_policy_document.this.json
  tags                = var.tags
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
