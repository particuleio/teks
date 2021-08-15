include {
  path = find_in_parent_folders()
  expose = true
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=v3.4.0"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  endpoints = {
    s3 = {
      service             = "s3"
      service_type        = "Gateway"
      private_dns_enabled = true
      route_table_ids     = flatten([dependency.vpc.outputs.intra_route_table_ids, dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids])
      tags                = { Name = "s3-vpc-endpoint" }
    },
  }
  tags = merge(
    include.locals.custom_tags
  )
}
