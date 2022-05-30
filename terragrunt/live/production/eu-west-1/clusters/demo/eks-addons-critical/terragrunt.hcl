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
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v6.2.0"
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

  cluster-name = dependency.eks.outputs.cluster_id

  tags = merge(
    include.root.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = dependency.eks.outputs.cluster_oidc_issuer_url
  }

  aws-for-fluent-bit = {
    enabled                          = true
    containers_log_retention_in_days = 14
  }

  aws-ebs-csi-driver = {
    enabled          = true
    is_default_class = true
    wait             = false
    use_encryption   = true
    use_kms          = true
  }

  aws-load-balancer-controller = {
    enabled = true
  }

  csi-external-snapshotter = {
    enabled = true
  }

  metrics-server = {
    enabled       = true
    allowed_cidrs = dependency.vpc.outputs.private_subnets_cidr_blocks
  }

  npd = {
    # Waiing for ARM image https://github.com/kubernetes/node-problem-detector/issues/586
    enabled      = true
    wait         = false
    extra_values = <<-EXTRA_VALUES
      nodeSelector:
        kubernetes.io/arch: amd64
      EXTRA_VALUES
  }

  tigera-operator = {
    enabled = true
  }

}
