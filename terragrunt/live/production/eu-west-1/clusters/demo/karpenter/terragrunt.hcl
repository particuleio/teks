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

terraform {
  source = "github.com/terraform-aws-modules/terraform-aws-eks//modules/karpenter?ref=v19.0.4"
}

inputs = {

  cluster_name = dependency.eks.outputs.cluster_name

  irsa_use_name_prefix = false
  irsa_oidc_provider_arn          = dependency.eks.outputs.oidc_provider_arn
  irsa_namespace_service_accounts = ["karpenter:karpenter"]

  create_iam_role = false
  iam_role_arn    = dependency.eks.outputs.eks_managed_node_groups["initial"].iam_role_arn

  tags = merge(
    include.root.locals.custom_tags
  )
}
