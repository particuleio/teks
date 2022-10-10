skip                          = true
terragrunt_version_constraint = ">= 0.36"

remote_state {
  backend = "s3"

  config = {
    bucket         = "${local.merged.prefix}-${local.merged.env}-tg-state-store"
    key            = "${local.merged.provider}/${path_relative_to_include()}/terraform.tfstate"
    region         = local.merged.tf_state_bucket_region
    encrypt        = true
    dynamodb_table = "${local.merged.prefix}-${local.merged.env}-tg-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

locals {
  merged = merge(
    try(yamldecode(file(find_in_parent_folders("global_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("env_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("zone_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("region_values.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("component_values.yaml"))), {})
  )
  custom_tags = merge(
    try(yamldecode(file(find_in_parent_folders("global_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("env_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("zone_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("region_tags.yaml"))), {}),
    try(yamldecode(file(find_in_parent_folders("component_tags.yaml"))), {})
  )
  full_name = "${local.merged.prefix}-${local.merged.env}-${local.merged.name}"
}

generate "provider-aws" {
  path      = "provider-aws.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    variable "provider_default_tags" {
      type = map
      default = {}
    }
    provider "aws" {
      region = "${local.merged.aws_region}"
      default_tags {
        tags = var.provider_default_tags
      }
    }
  EOF
}

# Disabled while waiting for
# https://github.com/hashicorp/terraform-provider-aws/issues/19204 to be
# resolved.
#inputs = {
#  provider_default_tags = local.custom_tags
#}

# Use this to impersonate a role, useful for EKS when you want a role to be
# the "root" use and not a personal AWS account
# iam_role = "arn:aws:iam::${yamldecode(file(find_in_parent_folders("global_values.yaml")))["aws_account_id"]}:role/administrator"
