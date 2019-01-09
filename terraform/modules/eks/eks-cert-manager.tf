//
// [cert-manager]
//
resource "aws_iam_policy" "eks-cert-manager" {
  count  = "${var.cert_manager["create_iam_resources"] ? 1 : 0 }"
  name   = "terraform-eks-${var.cluster-name}-cert-manager"
  policy = "${var.cert_manager["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-cert-manager" {
  count      = "${var.cert_manager["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-node.*.name[var.cert_manager["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-cert-manager.arn}"
}
