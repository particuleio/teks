include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-kms.git?ref=v2.2.1"
}

dependency "datasources" {
  config_path = "../../../datasources"
}

inputs = {

  description = "Encryption Key for EBS root volume of ${include.root.locals.full_name} instances"

  aliases = [
    "${include.root.locals.full_name}-ebs-root-encryption"
  ]

  key_administrators                = ["arn:${dependency.datasources.outputs.aws_partition}:iam::${dependency.datasources.outputs.aws_account_id}:root"]
  key_service_roles_for_autoscaling = ["arn:${dependency.datasources.outputs.aws_partition}:iam::${dependency.datasources.outputs.aws_account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"]
  key_statements = [
    {
      sid = "Allow access through EBS for all principals in the account that are authorized to use EBS"
      actions = [
        "kms:Decrypt",
        "kms:Encrypt",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["*"]
        }
      ]
      conditions = [
        {
          test     = "StringEquals"
          variable = "kms:CallerAccount"
          values = [
            include.root.locals.merged.aws_account_id,
          ]
        },
        {
          test     = "StringEquals"
          variable = "kms:ViaService"
          values = [
            "ec2.${include.root.locals.merged.aws_account_id}.amazonaws.com"
          ]
        },

      ]
    },
    {
      sid = "Allow direct access to key metadata to the account"
      actions = [
        "kms:Describe",
        "kms:Get*",
        "kms:List*",
        "kms:RevokeGrant"
      ]
      principals = [
        {
          type        = "AWS"
          identifiers = ["arn:aws:iam::${include.root.locals.merged.aws_account_id}:root"]
        }
      ]
    }
  ]
  tags = merge(
    include.root.locals.custom_tags
  )
}
