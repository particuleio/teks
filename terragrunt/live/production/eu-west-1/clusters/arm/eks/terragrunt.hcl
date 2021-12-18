include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../vpc", "../encryption-config"]
}

terraform {
  source = "github.com/particuleio/terraform-aws-eks?ref=v17.23.0"

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
    "region" = include.locals.merged.aws_region
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
  cluster_log_retention_in_days = 7

  map_users = [
    {
      userarn  = "arn:aws:iam::128478261352:user/github-actions"
      username = "github-action-iac"
      groups   = ["system:masters"]
    }
  ]

  node_groups_defaults = {
    disk_size              = 10
    create_launch_template = true
    ami_type               = "AL2_x86_64"
    min_capacity           = 0
    max_capacity           = 10
    desired_capacity       = 0
    container_runtime      = "containerd"
    capacity_type          = "ON_DEMAND"
    use_max_pods           = false
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
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[0]]
      kubelet_extra_args = "--max-pods=110"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "default-b-" = {
      desired_capacity   = 1
      ami_type           = "AL2_ARM_64"
      instance_types     = ["t4g.medium"]
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[1]]
      kubelet_extra_args = "--max-pods=110"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "default-c-" = {
      desired_capacity   = 1
      ami_type           = "AL2_ARM_64"
      instance_types     = ["t4g.medium"]
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[2]]
      kubelet_extra_args = "--max-pods=110"
      taints             = []
      k8s_labels = {
        size                            = "medium"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "c6g-xlarge-pub-a-" = {
      name_prefix        = "c6g-xlarge-pub-a-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.xlarge"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "c6g-xlarge-pub-b-" = {
      name_prefix        = "c6g-xlarge-pub-b-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.xlarge"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "c6g-xlarge-pub-c-" = {
      name_prefix        = "c6g-xlarge-pub-c-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.xlarge"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "c6g-large-pub-a-" = {
      name_prefix        = "c6g-large-pub-a-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.large"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.large"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "c6g-large-pub-b-" = {
      name_prefix        = "c6g-large-pub-b-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.large"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.large"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "c6g-large-pub-c-" = {
      name_prefix        = "c6g-large-pub-c-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.large"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.large"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "c6g-medium-pub-a-" = {
      name_prefix        = "c6g-medium-pub-a-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.medium"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      kubelet_extra_args = "--max-pods=98"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.medium"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "c6g-medium-pub-b-" = {
      name_prefix        = "c6g-medium-pub-b-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.medium"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      kubelet_extra_args = "--max-pods=98"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.medium"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "c6g-medium-pub-c-" = {
      name_prefix        = "c6g-medium-pub-c-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["c6g.medium"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      kubelet_extra_args = "--max-pods=98"
      public_ip          = true
      k8s_labels = {
        size                            = "c6g.medium"
        network                         = "public"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "c5-2xlarge-a-" = {
      name_prefix        = "c5-2xlarge-a-"
      desired_capacity   = 0
      instance_types     = ["c5.2xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c5.xlarge"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "c5-2xlarge-b-" = {
      name_prefix        = "c5-2xlarge-b-"
      desired_capacity   = 0
      instance_types     = ["c5.2xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c5.2xlarge"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "c5-2xlarge-c-" = {
      name_prefix        = "c5-2xlarge-b-"
      desired_capacity   = 0
      instance_types     = ["c5.2xlarge"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      kubelet_extra_args = "--max-pods=110"
      public_ip          = true
      k8s_labels = {
        size                            = "c5.2xlarge"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "t3a-micro-a-" = {
      name_prefix        = "t3a-micro-a-"
      desired_capacity   = 0
      instance_types     = ["t3a.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[0]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t3a.micro"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "t3a-micro-b-" = {
      name_prefix        = "t3a-micro-b-"
      desired_capacity   = 0
      instance_types     = ["t3a.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[1]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t3a.micro"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "t3a-micro-c-" = {
      name_prefix        = "t3a-micro-c-"
      desired_capacity   = 0
      instance_types     = ["t3a.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.public_subnets[2]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t3a.micro"
        network                         = "public"
        arch                            = "amd64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

    "t4g-micro-a-" = {
      name_prefix        = "t4g-micro-a-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["t4g.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[0]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t4g.micro"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}a"
      }
    }

    "t4g-micro-b-" = {
      name_prefix        = "t4g-micro-b-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["t4g.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[1]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t4g.micro"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}b"
      }
    }

    "t4g-micro-c-" = {
      name_prefix        = "t4g-micro-c-"
      ami_type           = "AL2_ARM_64"
      desired_capacity   = 0
      instance_types     = ["t4g.micro"]
      subnets            = [local.vpc.dependency.vpc.outputs.private_subnets[2]]
      kubelet_extra_args = "--max-pods=34"
      public_ip          = true
      k8s_labels = {
        size                            = "t4g.micro"
        network                         = "private"
        arch                            = "arm64"
        "topology.ebs.csi.aws.com/zone" = "${include.locals.merged.aws_region}c"
      }
    }

  }
}
