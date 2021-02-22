module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

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

  enable_ipv6                     = true
  assign_ipv6_address_on_creation = true

  public_subnet_ipv6_prefixes  = [0, 1, 2]
  private_subnet_ipv6_prefixes = [3, 4, 5]

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

output "vpc" {
  value = module.vpc
}
