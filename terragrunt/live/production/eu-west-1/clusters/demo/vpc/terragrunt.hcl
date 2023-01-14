include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.19.0"
}

dependency "datasources" {
  config_path = "../../../datasources"
}

locals {
  vpc_cidr = "10.42.0.0/16"
}

inputs = {

  tags = merge(
    include.root.locals.custom_tags,
    {
      "kubernetes.io/cluster/${include.root.locals.full_name}" = "shared",
    }
  )

  name = include.root.locals.full_name
  cidr = local.vpc_cidr
  azs  = dependency.datasources.outputs.aws_availability_zones.names

  intra_subnets   = [for k, v in slice(dependency.datasources.outputs.aws_availability_zones.names, 0, 3) : cidrsubnet(local.vpc_cidr, 8, k)]
  public_subnets  = [for k, v in slice(dependency.datasources.outputs.aws_availability_zones.names, 0, 3) : cidrsubnet(local.vpc_cidr, 3, k + 1)]
  private_subnets = [for k, v in slice(dependency.datasources.outputs.aws_availability_zones.names, 0, 3) : cidrsubnet(local.vpc_cidr, 3, k + 4)]

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]
  private_subnet_ipv6_prefixes    = [3, 4, 5]
  intra_subnet_ipv6_prefixes      = [6, 7, 8]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  manage_default_security_group = true

  default_security_group_egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
    }
  ]
  default_security_group_ingress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = "0.0.0.0/0"
      ipv6_cidr_blocks = "::/0"
    }
  ]

  public_subnet_tags = {
    "kubernetes.io/cluster/${include.root.locals.full_name}" = "shared"
    "kubernetes.io/role/elb"                                 = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${include.root.locals.full_name}" = "shared"
    "kubernetes.io/role/internal-elb"                        = "1"
  }

  enable_flow_log                                 = true
  create_flow_log_cloudwatch_log_group            = true
  create_flow_log_cloudwatch_iam_role             = true
  flow_log_cloudwatch_log_group_retention_in_days = 365
  flow_log_traffic_type                           = "REJECT"
}
