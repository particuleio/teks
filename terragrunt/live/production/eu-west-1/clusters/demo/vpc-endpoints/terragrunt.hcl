include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

include "vpc" {
  path           = "../../../../../../dependency-blocks/vpc.hcl"
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc//modules/vpc-endpoints?ref=v5.12.1"
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  endpoints = {
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = flatten([dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids])
      tags            = { Name = "${include.root.locals.merged.prefix}-${include.root.locals.merged.env}-s3-vpc-endpoint" }
    },
    dynamodb = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = flatten([dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids])
      tags            = { Name = "${include.root.locals.merged.prefix}-${include.root.locals.merged.env}-dynamodb-vpc-endpoint" }
    },
    kms = {
      service             = "kms"
      service_type        = "Interface"
      subnet_ids          = flatten([dependency.vpc.outputs.private_subnets])
      security_group_ids  = [dependency.vpc.outputs.default_security_group_id]
      private_dns_enabled = true
      tags                = { Name = "${include.root.locals.merged.prefix}-${include.root.locals.merged.env}-kms-vpc-endpoint" }
    },
    ec2 = {
      service             = "ec2"
      service_type        = "Interface"
      subnet_ids          = flatten([dependency.vpc.outputs.private_subnets])
      security_group_ids  = [dependency.vpc.outputs.default_security_group_id]
      private_dns_enabled = true
      tags                = { Name = "${include.root.locals.merged.prefix}-${include.root.locals.merged.env}-ec2-vpc-endpoint" }
    },
  }
  tags = merge(
    include.root.locals.custom_tags
  )
}
