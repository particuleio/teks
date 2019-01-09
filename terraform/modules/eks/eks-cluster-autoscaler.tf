//
// [cluster-autoscaler]
//
resource "aws_iam_policy" "eks-cluster-autoscaler" {
  count  = "${var.cluster_autoscaler["create_iam_resources"] ? 1 : 0 }"
  name   = "terraform-eks-${var.cluster-name}-cluster-autoscaler"
  policy = "${var.cluster_autoscaler["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler" {
  count      = "${var.cluster_autoscaler["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-node.*.name[var.cluster_autoscaler["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-cluster-autoscaler.arn}"
}
