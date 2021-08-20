include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../vpc"]
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=v3.6.0"
}

locals {
  vpc = read_terragrunt_config("../../../../../../dependency-blocks/vpc.hcl")
}

inputs = {
  vpc_id = local.vpc.dependency.vpc.outputs.vpc_id
  endpoints = {
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = true
      route_table_ids     = flatten([local.vpc.dependency.vpc.outputs.intra_route_table_ids, local.vpc.dependency.vpc.outputs.private_route_table_ids, local.vpc.dependency.vpc.outputs.public_route_table_ids])
      tags                = { Name = "s3-vpc-endpoint" }
    },
  }
  tags = merge(
    include.locals.custom_tags
  )
}
