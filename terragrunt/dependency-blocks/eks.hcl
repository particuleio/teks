skip = true

dependency "eks" {
  config_path = "${get_original_terragrunt_dir()}/../eks"

  mock_outputs = {
    cluster_id              = "cluster-name"
    cluster_oidc_issuer_url = "https://oidc.eks.eu-west-3.amazonaws.com/id/0000000000000000"
    node_groups             = {}
    aws_auth_configmap_yaml = yamlencode("")
  }
}
