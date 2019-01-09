//
// [external-dns]
//
resource "aws_iam_policy" "eks-external-dns" {
  count  = "${var.external_dns["create_iam_resources"] ? 1 : 0 }"
  name   = "terraform-eks-${var.cluster-name}-external-dns"
  policy = "${var.external_dns["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-external-dns" {
  count      = "${var.external_dns["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-node.*.name[var.cluster_autoscaler["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-external-dns.arn}"
}
