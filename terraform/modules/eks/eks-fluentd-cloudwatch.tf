//
// [fluentd-cloudwatch]
//
resource "aws_iam_policy" "eks-fluentd-cloudwatch" {
  count  = var.fluentd_cloudwatch["create_iam_resources"] ? 1 : var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0
  name   = "terraform-eks-${var.cluster-name}-fluentd-cloudwatch"
  policy = var.fluentd_cloudwatch["iam_policy"]
}

resource "aws_iam_role_policy_attachment" "eks-fluentd-cloudwatch" {
  count      = var.fluentd_cloudwatch["create_iam_resources"] ? length(var.node-pools) : 0
  role       = aws_iam_role.eks-node[count.index].name
  policy_arn = aws_iam_policy.eks-fluentd-cloudwatch[0].arn
}

resource "aws_iam_role" "eks-fluentd-cloudwatch-kiam" {
  name  = "terraform-eks-${var.cluster-name}-fluentd-cloudwatch-kiam"
  count = var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-fluentd-cloudwatch-kiam" {
  count      = var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-fluentd-cloudwatch-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-fluentd-cloudwatch[count.index].arn
}

output "fluentd-cloudwatch-kiam-role-arn" {
  value = aws_iam_role.eks-fluentd-cloudwatch-kiam.*.arn
}

