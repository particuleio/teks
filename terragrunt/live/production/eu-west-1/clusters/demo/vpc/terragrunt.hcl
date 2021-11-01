include {
  path   = find_in_parent_folders()
  expose = true
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.10.0"
}

locals {
  cidr = "10.0.0.0/16"
  azs = [
    "${include.locals.merged.aws_region}a",
    "${include.locals.merged.aws_region}b",
    "${include.locals.merged.aws_region}c"
  ]
  subnets         = cidrsubnets(local.cidr, 3, 3, 3, 3, 3, 3)
  private_subnets = chunklist(local.subnets, 3)[0]
  public_subnets  = chunklist(local.subnets, 3)[1]
}

inputs = {
  tags = merge(
    include.locals.custom_tags
  )

  name = include.locals.full_name

  cidr = local.cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]
  private_subnet_ipv6_prefixes    = [3, 4, 5]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${include.locals.full_name}" = "shared"
    "kubernetes.io/role/elb"                            = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${include.locals.full_name}" = "shared"
    "kubernetes.io/role/internal-elb"                   = "1"
  }
}
