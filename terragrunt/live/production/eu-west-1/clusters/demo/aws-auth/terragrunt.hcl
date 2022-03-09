include "root" {
  path           = find_in_parent_folders()
  expose         = true
  merge_strategy = "deep"
}

include "eks" {
  path           = "../../../../../../dependency-blocks/eks.hcl"
  expose         = true
  merge_strategy = "deep"
}

generate "provider-local" {
  path      = "provider-local.tf"
  if_exists = "overwrite"
  contents  = file("../../../../../../provider-config/eks-addons/eks-addons.tf")
}

terraform {
  source = "../../../../../../snippets/eks-aws-auth"
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  aws_auth_computed = dependency.eks.outputs.aws_auth_configmap_yaml

  aws_auth_extra_roles = <<-EOF
    - rolearn: arn:aws:iam::00000:role/demo
      username: admin
      groups:
        - system:masters
    EOF
  aws_auth_extra_users = <<-EOF
    mapUsers: |
      - userarn: arn:aws:iam::161285725140:user/klefevre
        username: admin
        groups:
          - system:masters
    EOF
}
