include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../vpc", "../encryption-config"]
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v17.11.0"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig label ns kube-system name=kube-system --overwrite"]
  }

  after_hook "undefault-gp2" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig patch storageclass gp2 -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}'"]
  }
}

locals {
  vpc               = read_terragrunt_config("../../../../../../dependency-blocks/vpc.hcl")
  encryption_config = read_terragrunt_config("../../../../../../dependency-blocks/encryption-config.hcl")
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks/eks.tf")
}

inputs = {

  aws = {
    "region" = include.locals.aws_region
  }

  tags = merge(
    include.locals.custom_tags
  )

  cluster_name = include.locals.full_name
  subnets      = local.vpc.dependency.vpc.outputs.private_subnets
  vpc_id       = local.vpc.dependency.vpc.outputs.vpc_id

  write_kubeconfig = false
  enable_irsa      = true

  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    include.locals.full_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  cluster_version                 = "1.21"
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_encryption_config = [
    {
      provider_key_arn = local.encryption_config.dependency.encryption_config.outputs.arn
      resources        = ["secrets"]
    }
  ]

  node_groups_defaults = {
    disk_size               = 10
    create_launch_template  = true
    launch_template_version = 1
    ami_type                = "AL2_ARM_64"
    min_capacity            = 0
    max_capacity            = 5
  }

  node_groups = {

    "default-a" = {
      desired_capacity = 1
      instance_types   = ["t4g.medium"]
      subnets          = [local.vpc.dependency.vpc.outputs.private_subnets[0]]
      k8s_labels = {
        pool = "default"
      }
      capacity_type = "ON_DEMAND"
    }

    "default-b" = {
      desired_capacity = 1
      instance_types   = ["t4g.medium"]
      subnets          = [local.vpc.dependency.vpc.outputs.private_subnets[1]]
      k8s_labels = {
        pool = "default"
      }
      capacity_type = "ON_DEMAND"
    }

    "default-c" = {
      desired_capacity = 1
      instance_types   = ["t4g.medium"]
      subnets          = [local.vpc.dependency.vpc.outputs.private_subnets[2]]
      k8s_labels = {
        pool = "default"
      }
      capacity_type = "ON_DEMAND"
    }

    "large-a" = {
      desired_capacity        = 0
      instance_types          = ["t4g.large"]
      subnets                 = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      public_ip               = true
      k8s_labels = {
        pool = "large"
      }
      capacity_type = "SPOT"
      taints = [
        {
          key    = "dedicated"
          value  = "large"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    "large-b" = {
      desired_capacity        = 0
      instance_types          = ["t4g.large"]
      subnets                 = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      public_ip               = true
      k8s_labels = {
        pool = "large"
      }
      capacity_type = "SPOT"
      taints = [
        {
          key    = "dedicated"
          value  = "large"
          effect = "NO_SCHEDULE"
        }
      ]
    }

    "large-c" = {
      desired_capacity = 0
      instance_types   = ["t4g.large"]
      subnets          = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      public_ip        = true
      k8s_labels = {
        pool = "large"
      }
      capacity_type = "SPOT"
      taints = [
        {
          key    = "dedicated"
          value  = "large"
          effect = "NO_SCHEDULE"
        }
      ]
    }
  }
}
