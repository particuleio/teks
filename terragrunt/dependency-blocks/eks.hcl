skip = true

dependency "eks" {
  config_path = "${get_original_terragrunt_dir()}/../eks"

  mock_outputs = {
    cluster_id              = "cluster-id"
    cluster_name            = "cluster-name"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-3.amazonaws.com/id/0000000000000000"
    node_groups             = {}
    cluster_oidc_issuer_url = "oidc"
    oidc_provider_arn       = "arn:::"
    cluster_endpoint        = "endpoint"
    eks_managed_node_groups = {
      initial = {
        iam_role_arn = "arn:::"
      }
    }
  }
}
