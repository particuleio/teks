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
  source = "github.com/terraform-aws-modules/terraform-aws-eks?ref=v18.23.0"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "aws eks update-kubeconfig --name ${include.root.locals.full_name} --kubeconfig  ${get_terragrunt_dir()}/kubeconfig 2>/dev/null"]
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

  manage_aws_auth_configmap = true

  cluster_name                    = include.root.locals.full_name
  cluster_version                 = "1.21"
  cluster_enabled_log_types       = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  cluster_encryption_config = [
    {
      provider_key_arn = dependency.encryption_config.outputs.arn
      resources        = ["secrets"]
    }
  ]
  cluster_addons = {
    coredns = {
      addon_version     = "v1.8.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {
      addon_version     = "v1.21.2-eksbuild.2"
      resolve_conflicts = "OVERWRITE"
    }
    vpc-cni = {
      addon_version     = "v1.10.1-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = dependency.vpc.outputs.vpc_id
  subnet_ids = dependency.vpc.outputs.private_subnets

  enable_irsa = true

  cloudwatch_log_group_retention_in_days = 7

  node_security_group_additional_rules = {
    ingress_self_all = {
      from_port = 0
      to_port   = 0
      protocol  = "-1"
      type      = "ingress"
      self      = true
    }
    ingress_cluster_all = {
      from_port                     = 0
      to_port                       = 0
      protocol                      = "-1"
      type                          = "ingress"
      source_cluster_security_group = true
    }
    ingress_node_port_tcp = {
      from_port        = 30000
      to_port          = 32767
      protocol         = "tcp"
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    ingress_node_port_udp = {
      from_port        = 30000
      to_port          = 32767
      protocol         = "udp"
      type             = "ingress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
    egress_all = {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    force_update_version         = true
    desired_size                 = 1
    min_size                     = 0
    max_size                     = 10
    ebs_optimized                = true
    capacity_type                = "ON_DEMAND"
    iam_role_additional_policies = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]
    block_device_mappings = {
      root = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size = 15
          volume_type = "gp3"
        }
      }
    }
  }

  eks_managed_node_groups = {

    "default-a" = {
      desired_size            = 1
      ami_type                = "AL2_x86_64"
      platform                = "linux"
      instance_types          = ["t3a.large"]
      subnet_ids              = [dependency.vpc.outputs.private_subnets[0]]
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        set -ex
        cat <<-EOF > /etc/profile.d/bootstrap.sh
        export CONTAINER_RUNTIME="containerd"
        export USE_MAX_PODS=false
        export KUBELET_EXTRA_ARGS="--max-pods=${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t3a.large --cni-version 1.10.1 --cni-prefix-delegation-enabled")}"
        EOF
        # Source extra environment variables in bootstrap script
        sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
        cd /tmp
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_amd64/amazon-ssm-agent.rpm
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
        EOT
      labels = {
        network = "private"
      }
    }

    "default-b" = {
      ami_type                   = "BOTTLEROCKET_x86_64"
      platform                   = "bottlerocket"
      instance_types             = ["t3a.large"]
      subnet_ids                 = [dependency.vpc.outputs.private_subnets[1]]
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = <<-EOT
        "max-pods" = ${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t3a.large --cni-version 1.10.1 --cni-prefix-delegation-enabled")}
        EOT
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 2
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
        containers = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
      }
      labels = {
        network = "private"
      }
    }

    "default-c" = {
      ami_type                   = "BOTTLEROCKET_x86_64"
      platform                   = "bottlerocket"
      instance_types             = ["t3a.large"]
      subnet_ids                 = [dependency.vpc.outputs.private_subnets[2]]
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = <<-EOT
        "max-pods" = ${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t3a.large --cni-version 1.10.1 --cni-prefix-delegation-enabled")}
        EOT
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 2
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
        containers = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
      }
      labels = {
        network = "private"
      }
    }

    "arm-a" = {
      ami_type                = "AL2_ARM_64"
      instance_types          = ["t4g.medium"]
      subnet_ids              = [dependency.vpc.outputs.private_subnets[0]]
      pre_bootstrap_user_data = <<-EOT
        #!/bin/bash
        set -ex
        cat <<-EOF > /etc/profile.d/bootstrap.sh
        export CONTAINER_RUNTIME="containerd"
        export USE_MAX_PODS=false
        export KUBELET_EXTRA_ARGS="--max-pods=${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.medium --cni-version 1.10.1 --cni-prefix-delegation-enabled")}"
        EOF
        # Source extra environment variables in bootstrap script
        sed -i '/^set -o errexit/a\\nsource /etc/profile.d/bootstrap.sh' /etc/eks/bootstrap.sh
        cd /tmp
        sudo yum install -y https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/linux_arm64/amazon-ssm-agent.rpm
        sudo systemctl enable amazon-ssm-agent
        sudo systemctl start amazon-ssm-agent
        EOT
      labels = {
        network = "private"
      }
    }

    "arm-b" = {
      ami_type                   = "BOTTLEROCKET_ARM_64"
      platform                   = "bottlerocket"
      instance_types             = ["t4g.medium"]
      subnet_ids                 = [dependency.vpc.outputs.private_subnets[1]]
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = <<-EOT
        "max-pods" = ${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.medium --cni-version 1.10.1 --cni-prefix-delegation-enabled")}
        EOT
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 2
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
        containers = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
      }
      labels = {
        network = "private"
      }
    }

    "arm-c" = {
      ami_type                   = "BOTTLEROCKET_ARM_64"
      platform                   = "bottlerocket"
      instance_types             = ["t4g.medium"]
      subnet_ids                 = [dependency.vpc.outputs.private_subnets[2]]
      enable_bootstrap_user_data = true
      bootstrap_extra_args       = <<-EOT
        "max-pods" = ${run_cmd("/bin/sh", "-c", "../../../../../../../tools/max-pods-calculator.sh --instance-type t4g.large --cni-version 1.10.1 --cni-prefix-delegation-enabled")}
        EOT
      block_device_mappings = {
        root = {
          device_name = "/dev/xvda"
          ebs = {
            volume_size           = 2
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
        containers = {
          device_name = "/dev/xvdb"
          ebs = {
            volume_size           = 20
            volume_type           = "gp3"
            delete_on_termination = true
            encrypted             = true
            kms_key_id            = dependency.encryption_config.outputs.arn
          }
        }
      }
      labels = {
        network = "private"
      }
    }
  }
}
