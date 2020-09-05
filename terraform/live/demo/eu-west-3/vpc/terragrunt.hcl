include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-vpc?ref=v2.48.0"
}

locals {
  aws_region  = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env         = yamldecode(file("${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  prefix      = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["prefix"]
  custom_tags = yamldecode(file("${find_in_parent_folders("common_tags.yaml")}"))
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

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    terraform {
      backend "s3" {}
    }
  EOF
}

inputs = {

  tags = merge(
    {
      "kubernetes.io/cluster/${local.prefix}-${local.env}" = "shared"
    },
    local.custom_tags
  )

  name = "vpc-eks-${local.env}"

  cidr = "10.0.0.0/16"

  azs             = ["${local.aws_region}a", "${local.aws_region}b", "${local.aws_region}c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  assign_generated_ipv6_cidr_block = true

  enable_nat_gateway = true
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_s3_endpoint   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.prefix}-${local.env}" = "shared"
    "kubernetes.io/role/elb"                             = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.prefix}-${local.env}" = "shared"
    "kubernetes.io/role/internal-elb"                    = "1"
  }
}
