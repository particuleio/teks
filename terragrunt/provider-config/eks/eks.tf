provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
data "aws_eks_cluster" "cluster" {
  name = aws_eks_cluster.this[0].id
}
data "aws_eks_cluster_auth" "cluster" {
  name = aws_eks_cluster.this[0].id
}
