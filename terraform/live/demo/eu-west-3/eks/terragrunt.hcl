include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v8.2.0"

  before_hook "init" {
    commands = ["init"]
    execute  = ["bash", "-c", "wget -O terraform-provider-kubectl https://github.com/gavinbunney/terraform-provider-kubectl/releases/download/v1.2.1/terraform-provider-kubectl-linux-amd64 && chmod +x terraform-provider-kubectl"]
  }

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }
}

locals {
  aws_region     = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
  env            = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  aws_account_id = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_account_id"]
  custom_tags    = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))
  prefix         = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["prefix"]
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

  tags = merge(
    {
      "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    },
    local.custom_tags
  )

  cluster_name          = local.cluster_name
  subnets               = dependency.vpc.outputs.private_subnets
  vpc_id                = dependency.vpc.outputs.vpc_id
  write_kubeconfig      = false
  enable_irsa           = true

  kubeconfig_aws_authenticator_additional_args = []

  cluster_version           = "1.14"
  cluster_enabled_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  manage_worker_autoscaling_policy = false

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
      ]
    },
  ]

}

