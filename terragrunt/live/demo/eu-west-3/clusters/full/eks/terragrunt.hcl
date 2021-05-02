include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=master"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "kubeconfig-tg" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output --raw kubeconfig 2>/dev/null > kubeconfig"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig label ns kube-system name=kube-system --overwrite"]
  }

  after_hook "undefault-gp2" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig patch storageclass gp2 -p '{\"metadata\": {\"annotations\":{\"storageclass.kubernetes.io/is-default-class\":\"false\"}}}'"]
  }
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

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id = "vpc-00000000"
    private_subnets = [
      "subnet-00000000",
      "subnet-00000001",
      "subnet-00000002",
    ]
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"
    }
    provider "kubernetes" {
      host                   = data.aws_eks_cluster.cluster.endpoint
      cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
      token                  = data.aws_eks_cluster_auth.cluster.token
    }
    data "aws_eks_cluster" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
    data "aws_eks_cluster_auth" "cluster" {
      name = aws_eks_cluster.this[0].id
    }
  EOF
}

inputs = {

  aws = {
    "region" = local.aws_region
  }

  tags = merge(
    local.custom_tags
  )

  cluster_name                         = local.cluster_name
  subnets                              = dependency.vpc.outputs.private_subnets
  vpc_id                               = dependency.vpc.outputs.vpc_id
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
      desired_capacity       = 3
      max_capacity           = 5
      min_capacity           = 1
      instance_types         = ["m5a.large"]
      disk_size              = 50
      k8s_labels = {
        pool = "default"
      }
      capacity_type = "ON_DEMAND"
    }
    "dedicated-${local.aws_region}" = {
      create_launch_template = true
      desired_capacity       = 3
      max_capacity           = 5
      min_capacity           = 3
      instance_types         = ["m5a.large"]
      disk_size              = 50
      kubelet_extra_args     = "--register-with-taints=dedicated=spot:NoSchedule"
      k8s_labels = {
        pool = "dedicated"
      }
      capacity_type = "SPOT"
    }
  }
}
