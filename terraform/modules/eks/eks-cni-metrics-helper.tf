//
// [cni-metrics-helper]
//
resource "aws_iam_policy" "eks-cni-metrics-helper" {
  count  = "${var.cni_metrics_helper["create_iam_resources"] ? 1 : var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0 }"
  name   = "terraform-eks-${var.cluster-name}-cni-metrics-helper"
  policy = "${var.cni_metrics_helper["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper" {
  count      = "${var.cni_metrics_helper["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-node.*.name[var.cni_metrics_helper["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-cni-metrics-helper.arn}"
}

resource "aws_iam_role" "eks-cni-metrics-helper-kiam" {
  name  = "terraform-eks-${var.cluster-name}-cni-metrics-helper-kiam"
  count = "${var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0 }"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.eks-kiam-server-role.*.arn[count.index]}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper-kiam" {
  count      = "${var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-cni-metrics-helper-kiam.*.name[count.index]}"
  policy_arn = "${aws_iam_policy.eks-cni-metrics-helper.*.arn[count.index]}"
}

output "cni-metrics-helper-kiam-role-arn" {
  value = "${aws_iam_role.eks-cni-metrics-helper-kiam.*.arn}"
}
