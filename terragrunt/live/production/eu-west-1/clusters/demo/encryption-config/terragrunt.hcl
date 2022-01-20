include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/particuleio/terraform-aws-kms.git?ref=v1.0.2"
}

inputs = {
  description = "EKS Secret Encryption Key for ${include.root.locals.full_name}"
  alias       = "${include.root.locals.full_name}_secret_encryption"
  tags = merge(
    include.root.locals.custom_tags
  )
  policy_flavor = "eks_root_volume_encryption"
}
