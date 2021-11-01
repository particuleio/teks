include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "github.com/particuleio/terraform-kubernetes-addons.git//modules/aws?ref=v2.32.0"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

locals {
  vpc = read_terragrunt_config("../../../../../../dependency-blocks/vpc.hcl")
  eks = read_terragrunt_config("../../../../../../dependency-blocks/eks.hcl")
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

  cluster-name = local.eks.dependency.eks.outputs.cluster_id

  tags = merge(
    include.locals.custom_tags
  )

  eks = {
    "cluster_oidc_issuer_url" = local.eks.dependency.eks.outputs.cluster_oidc_issuer_url
  }

  aws-ebs-csi-driver = {
    enabled          = true
    is_default_class = true
    wait             = true
    use_encryption   = true
    use_kms          = true
  }

  aws-load-balancer-controller = {
    enabled = true
  }

  metrics-server = {
    enabled = true
  }

  npd = {
    enabled = true
  }

  tigera-operator = {
    enabled = true
  }

}
