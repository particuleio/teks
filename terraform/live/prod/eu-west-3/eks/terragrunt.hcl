include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v12.1.0"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.4.2/terraform-provider-kubectl-linux-amd64 && chmod +x terraform-provider-kubectl"]
  }

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "kubeconfig-tg" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > kubeconfig"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig label ns kube-system name=kube-system --overwrite"]
  }

  after_hook "remove-default-psp" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig delete psp eks.privileged || true"]
  }
  after_hook "remove-default-psp-clusterrolebindind" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig delete clusterrolebinding eks:podsecuritypolicy:authenticated || true"]
  }
  after_hook "remove-default-psp-clusterrole" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig kubeconfig delete clusterrole eks:podsecuritypolicy:privileged || true"]
  }
}

locals {
  aws_region     = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env            = yamldecode(file("${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  aws_account_id = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["aws_account_id"]
  custom_tags    = yamldecode(file("${find_in_parent_folders("common_tags.yaml")}"))
  prefix         = yamldecode(file("${find_in_parent_folders("common_values.yaml")}"))["prefix"]
  cluster_name   = "eks-${local.prefix}-${local.env}"
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

inputs = {

  aws = {
    "region" = local.aws_region
  }

  psp_privileged_ns = [
    "istio-system",
    "istio-operator",
    "monitoring",
    "aws-alb-ingress-controller",
    "aws-for-fluent-bit"
  ]

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

  cluster_version           = "1.16"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  worker_groups_launch_template = [
    {
      name                 = "default-${local.aws_region}a"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[0]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          propagate_at_launch = "false"
          value               = "true"
        }
      ]
    },
    {
      name                 = "default-${local.aws_region}b"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[1]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          propagate_at_launch = "false"
          value               = "true"
        }
      ]
    },
    {
      name                 = "default-${local.aws_region}c"
      instance_type        = "t3.medium"
      asg_min_size         = 1
      asg_max_size         = 3
      asg_desired_capacity = 1
      subnets              = [dependency.vpc.outputs.private_subnets[2]]
      autoscaling_enabled  = true
      root_volume_size     = 50
      tags = [
        {
          key                 = "CLUSTER_ID"
          value               = local.cluster_name
          propagate_at_launch = true
        },
        {
          key                 = "k8s.io/cluster-autoscaler/enabled"
          propagate_at_launch = "false"
          value               = "true"
        },
        {
          key                 = "k8s.io/cluster-autoscaler/${local.cluster_name}"
          propagate_at_launch = "false"
          value               = "true"
        }
      ]
    },
  ]
}
