locals {
  addons_cluster_name = element(concat(aws_eks_cluster.this.*.id, [""]), 0)
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = local.addons_cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "vpc-cni"
  addon_version     = "v1.10.1-eksbuild.1"
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = local.addons_cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "coredns"
  addon_version     = "v1.8.4-eksbuild.1"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = local.addons_cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "kube-proxy"
  addon_version     = "v1.21.2-eksbuild.2"
}
