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

include "eks" {
  path           = "../../../../../../dependency-blocks/eks.hcl"
  expose         = true
  merge_strategy = "deep"
}


terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v15.3.0"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

generate "provider-github" {
  path      = "provider-github.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "github" {
      owner = "${include.root.locals.merged.github_owner}"
    }
  EOF
}

inputs = {

  priority-class = {
    name  = basename(get_terragrunt_dir())
    value = "90000"
  }

  priority-class-ds = {
    name   = "${basename(get_terragrunt_dir())}-ds"
    values = "100000"
  }

  cluster-name = dependency.eks.outputs.cluster_name

  tags = merge(
    include.root.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
    "oidc_provider_arn"       = dependency.eks.outputs.oidc_provider_arn
    "cluster_endpoint"        = dependency.eks.outputs.cluster_endpoint
  }

  aws-for-fluent-bit = {
    enabled                          = true
    containers_log_retention_in_days = 365
  }

  aws-ebs-csi-driver = {
    enabled          = true
    is_default_class = true
    wait             = false
    use_encryption   = true
    use_kms          = true
  }

  aws-efs-csi-driver = {
    enabled = true
  }

  aws-load-balancer-controller = {
    enabled      = true
    extra_values = <<-EXTRA_VALUES
      image:
        repository: 602401143452.dkr.ecr.eu-west-1.amazonaws.com/amazon/aws-load-balancer-controller
      EXTRA_VALUES
  }

  csi-external-snapshotter = {
    enabled = true
  }

  external-dns = {
    external-dns = {
      enabled = true
    },
  }

  karpenter = {
    enabled      = true
    iam_role_arn = dependency.eks.outputs.eks_managed_node_groups["unused"].iam_role_arn
  }

  metrics-server = {
    enabled       = true
    allowed_cidrs = dependency.vpc.outputs.intra_subnets_cidr_blocks
  }

  npd = {
    enabled = true
    wait    = false
  }

  tigera-operator = {
    enabled = false
  }

  velero = {
    enabled = false
  }
}
