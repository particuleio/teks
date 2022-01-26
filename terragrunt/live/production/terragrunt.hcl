skip                          = true
terragrunt_version_constraint = ">= 0.32"

remote_state {
  backend = "s3"

  config = {
    bucket         = "${yamldecode(file(find_in_parent_folders("global_values.yaml")))["prefix"]}-${yamldecode(file(find_in_parent_folders("env_values.yaml")))["env"]}-tg-state-store"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    region         = "${yamldecode(file(find_in_parent_folders("global_values.yaml")))["tf_state_bucket_region"]}"
    encrypt        = true
    dynamodb_table = "${yamldecode(file(find_in_parent_folders("global_values.yaml")))["prefix"]}-${yamldecode(file(find_in_parent_folders("env_values.yaml")))["env"]}-tg-state-lock"
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

locals {
  merged = merge(
    yamldecode(file(find_in_parent_folders("global_values.yaml"))),
    yamldecode(file(find_in_parent_folders("env_values.yaml"))),
    yamldecode(file(find_in_parent_folders("region_values.yaml"))),
    yamldecode(file(find_in_parent_folders("component_values.yaml")))
  )
  custom_tags = merge(
    yamldecode(file(find_in_parent_folders("global_tags.yaml"))),
    yamldecode(file(find_in_parent_folders("env_tags.yaml"))),
    yamldecode(file(find_in_parent_folders("region_tags.yaml"))),
    yamldecode(file(find_in_parent_folders("component_tags.yaml")))
  )
  full_name = "${local.merged.prefix}-${local.merged.env}-${local.merged.name}"
}

generate "provider-aws" {
  path      = "provider-aws.tf"
  if_exists = "overwrite"
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
    data "aws_default_tags" "current" {}
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
# iam_role = "arn:aws:iam::${yamldecode(file("global_values.yaml"))["aws_account_id"]}:role/administrator"
