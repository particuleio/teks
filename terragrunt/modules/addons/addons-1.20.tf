resource "aws_eks_addon" "vpc_cni" {
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "vpc-cni"
  addon_version     = "v1.7.10-eksbuild.1"
}

resource "aws_eks_addon" "coredns" {
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "coredns"
  addon_version     = "v1.8.3-eksbuild.1"
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.cluster_name
  resolve_conflicts = "OVERWRITE"
  addon_name        = "kube-proxy"
  addon_version     = "v1.20.4-eksbuild.2"
}
