include {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "../../../../../../modules/kms-key"
}

inputs = {

  description = "EKS Secret Encryption Key for ${include.locals.full_name}"
  alias       = "${include.locals.full_name}_encryption"
  tags = merge(
    include.locals.custom_tags
  )

}
