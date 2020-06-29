include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-aws-ecr.git?ref=v2.1.0"
}

locals {
  aws_region  = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env         = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  project     = "namespace"
  prefix      = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["prefix"]
  custom_tags = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))
}

inputs = {

  env     = local.env
  project = local.project
  prefix  = local.prefix

  aws = {
    "region" = local.aws_region
  }

  custom_tags = merge(
    local.custom_tags
  )

  registries = [
    {
      name                 = "${local.project}/myapp"
      image_tag_mutability = "MUTABLE"
      scan_on_push         = true
    },
  ]

  registries_policies = [
  ]
}
