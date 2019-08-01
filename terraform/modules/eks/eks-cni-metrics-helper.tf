//
// [cni-metrics-helper]
//
resource "aws_iam_policy" "eks-cni-metrics-helper" {
  count  = var.cni_metrics_helper["create_iam_resources"] ? 1 : var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0
  name   = "terraform-eks-${var.cluster-name}-cni-metrics-helper"
  policy = var.cni_metrics_helper["iam_policy"]
}

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper" {
  count      = var.cni_metrics_helper["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-node[var.cni_metrics_helper["attach_to_pool"]].name
  policy_arn = aws_iam_policy.eks-cni-metrics-helper[0].arn
}

resource "aws_iam_role" "eks-cni-metrics-helper-kiam" {
  name  = "terraform-eks-${var.cluster-name}-cni-metrics-helper-kiam"
  count = var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0

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
        "AWS": "${aws_iam_role.eks-kiam-server-role[count.index].arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper-kiam" {
  count      = var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cni-metrics-helper-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cni-metrics-helper[count.index].arn
}

output "cni-metrics-helper-kiam-role-arn" {
  value = aws_iam_role.eks-cni-metrics-helper-kiam.*.arn
}

