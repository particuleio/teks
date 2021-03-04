locals {
  cluster_name = "${local.prefix}-${local.env}"
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "< 14"

  tags = merge(
    local.custom_tags
  )

  cluster_name                         = local.cluster_name
  subnets                              = data.terraform_remote_state.vpc.outputs.vpc.private_subnets
  vpc_id                               = data.terraform_remote_state.vpc.outputs.vpc.vpc_id
  write_kubeconfig                     = true
  enable_irsa                          = true
  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    local.cluster_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  cluster_version           = "1.19"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    "default-${local.aws_region}a" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [data.terraform_remote_state.vpc.outputs.vpc.private_subnets[0]]
      disk_size        = 50
    }

    "default-${local.aws_region}b" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [data.terraform_remote_state.vpc.outputs.vpc.private_subnets[1]]
      disk_size        = 50
    }

    "default-${local.aws_region}c" = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1
      instance_type    = "t3a.medium"
      subnets          = [data.terraform_remote_state.vpc.outputs.vpc.private_subnets[2]]
      disk_size        = 50
    }
  }
}

output "eks" {
  value = module.eks
}
