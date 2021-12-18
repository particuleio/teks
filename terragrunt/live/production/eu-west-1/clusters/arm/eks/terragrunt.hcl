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

include "encryption_config" {
  path           = "../../../../../../dependency-blocks/encryption-config.hcl"
  expose         = true
  merge_strategy = "deep"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v17.24.0"

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

  after_hook "vpc-cni-prefix-delegation" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig set env daemonset aws-node -n kube-system ENABLE_PREFIX_DELEGATION=true"]
  }

  after_hook "vpc-cni-prefix-warm-prefix" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig set env daemonset aws-node -n kube-system WARM_PREFIX_TARGET=1"]
  }
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks/eks.tf")
}

inputs = {

  aws = {
    "region" = include.root.locals.merged.aws_region
  }

  tags = merge(
    include.root.locals.custom_tags
  )

  cluster_name = include.root.locals.full_name
  subnets      = dependency.vpc.outputs.private_subnets
  vpc_id       = dependency.vpc.outputs.vpc_id

  write_kubeconfig = false
  enable_irsa      = true

  kubeconfig_aws_authenticator_command = "aws"
  kubeconfig_aws_authenticator_command_args = [
    "eks",
    "get-token",
    "--cluster-name",
    include.root.locals.full_name
  ]
  kubeconfig_aws_authenticator_additional_args = []

  cluster_version                 = "1.21"
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_encryption_config = [
    {
      provider_key_arn = dependency.encryption_config.outputs.arn
      resources        = ["secrets"]
    }
  ]
  cluster_log_retention_in_days = 7

  node_groups_defaults = {
    disk_size              = 10
    create_launch_template = true
    ami_type               = "AL2_x86_64"
    min_capacity           = 0
    max_capacity           = 10
    desired_capacity       = 0
    capacity_type          = "ON_DEMAND"
    bootstrap_env = {
      USE_MAX_PODS      = false
      CONTAINER_RUNTIME = "containerd"
    }
    taints = [
      {
        key    = "dedicated"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]
  }

  node_groups = {

    "default-a-" = {
      desired_capacity   = 1
      ami_type           = "AL2_ARM_64"
      instance_types     = ["t4g.medium"]
      subnets            = [dependency.vpc.outputs.private_subnets[0]]
      kubelet_extra_args = "--max-pods=${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.medium --cni-version 1.9.1 --cni-prefix-delegation-enabled")}"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.root.locals.merged.aws_region}a"
      }
    }

    "default-b-" = {
      desired_capacity   = 1
      ami_type           = "AL2_ARM_64"
      instance_types     = ["t4g.medium"]
      subnets            = [dependency.vpc.outputs.private_subnets[1]]
      kubelet_extra_args = "--max-pods=${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.medium --cni-version 1.9.1 --cni-prefix-delegation-enabled")}"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.root.locals.merged.aws_region}b"
      }
    }

    "default-c-" = {
      desired_capacity   = 1
      ami_type           = "AL2_ARM_64"
      instance_types     = ["t4g.medium"]
      subnets            = [dependency.vpc.outputs.private_subnets[2]]
      kubelet_extra_args = "--max-pods=${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.medium --cni-version 1.9.1 --cni-prefix-delegation-enabled")}"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }
  }
}
