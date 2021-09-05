resource "aws_kms_key" "this" {
  description = var.description
  tags        = var.tags
  policy      = data.aws_iam_policy_document.ebs_decryption.json
}

resource "aws_kms_alias" "this" {
  name          = "alias/${var.alias}"
  target_key_id = aws_kms_key.this.key_id
}
