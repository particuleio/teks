include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v1.5.0"
}

dependency "datasources" {
  config_path = "../../../datasources"
}

inputs = {

  description = "EKS Secret Encryption Key for ${include.root.locals.full_name}"

  aliases = [
    "${include.root.locals.full_name}_secret_encryption"
  ]

  key_administrators = ["arn:${dependency.datasources.outputs.aws_partition}:iam::${dependency.datasources.outputs.aws_account_id}:root"]
  key_users          = ["arn:${dependency.datasources.outputs.aws_partition}:iam::${dependency.datasources.outputs.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
  key_service_users  = ["arn:${dependency.datasources.outputs.aws_partition}:iam::${dependency.datasources.outputs.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]

  tags = merge(
    include.root.locals.custom_tags
  )
}
