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
  source = "github.com/particuleio/terraform-eks-aws-auth.git?ref=v1.1.0"
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  aws_auth_computed = dependency.eks.outputs.aws_auth_configmap_yaml

  aws_auth = <<-EOF
    data:
      mapUsers: |
        - userarn: arn:aws:iam::161285725140:user/klefevre
          username: admin
          groups:
            - system:masters
    EOF
}
