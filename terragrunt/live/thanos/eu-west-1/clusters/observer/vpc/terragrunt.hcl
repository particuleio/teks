include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v3.0.0"
}

locals {
  aws_region = yamldecode(file("${find_in_parent_folders("region_values.yaml")}"))["aws_region"]
  env        = yamldecode(file("${find_in_parent_folders("env_tags.yaml")}"))["Env"]
  prefix     = yamldecode(file("${find_in_parent_folders("global_values.yaml")}"))["prefix"]
  name       = yamldecode(file("${find_in_parent_folders("cluster_values.yaml")}"))["name"]
  custom_tags = merge(
    yamldecode(file("${find_in_parent_folders("global_tags.yaml")}")),
    yamldecode(file("${find_in_parent_folders("env_tags.yaml")}"))
  )
  cluster_name = "${local.prefix}-${local.env}-${local.name}"
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
  EOF
}

inputs = {

  tags = merge(
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    },
    local.custom_tags
  )

  name = "vpc-eks-${local.env}"

  cidr = "10.0.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true
  public_subnet_ipv6_prefixes     = [0, 1, 2]
  private_subnet_ipv6_prefixes    = [3, 4, 5]

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}
