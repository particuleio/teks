include {
  path   = find_in_parent_folders()
  expose = true
}

dependencies {
  paths = ["../eks"]
}

terraform {
  source = "../../../../../../modules/eks-asg-tags"
}

locals {
  eks = read_terragrunt_config("../../../../../../dependency-blocks/eks.hcl")
}

inputs = {
  node_groups = local.eks.dependency.eks.outputs.node_groups
}
