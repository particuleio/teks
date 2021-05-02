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
  source = "terraform-aws-modules/eks/aws"

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
    "default-${local.aws_region}" = {
      create_launch_template = true
      desired_capacity       = 1
      max_capacity           = 5
      min_capacity           = 1
      instance_types         = ["t3a.medium", "t3.medium"]
      disk_size              = 50
      k8s_labels = {
        pool = "default"
      }
      capacity_type = "ON_DEMAND"
    }
    "dedicated-${local.aws_region}" = {
      create_launch_template = true
      desired_capacity       = 1
      max_capacity           = 5
      min_capacity           = 1
      instance_types         = ["t3a.medium", "t3.medium"]
      disk_size              = 50
      kubelet_extra_args     = "--register-with-taints=dedicated=spot:NoSchedule"
      k8s_labels = {
        pool = "dedicated"
      }
      capacity_type = "SPOT"
    }
  }
}

output "eks" {
  value = module.eks
}
