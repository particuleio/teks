//
// [cluster-autoscaler]
//
resource "aws_iam_policy" "eks-cluster-autoscaler" {
  count  = var.cluster_autoscaler["create_iam_resources"] ? 1 : var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0
  name   = "terraform-eks-${var.cluster-name}-cluster-autoscaler"
  policy = var.cluster_autoscaler["iam_policy"]
}

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler" {
  count      = var.cluster_autoscaler["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-node[var.cluster_autoscaler["attach_to_pool"]].name
  policy_arn = aws_iam_policy.eks-cluster-autoscaler[0].arn
}

resource "aws_iam_role" "eks-cluster-autoscaler-kiam" {
  name  = "terraform-eks-${var.cluster-name}-cluster-autoscaler-kiam"
  count = var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler-kiam" {
  count      = var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cluster-autoscaler-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cluster-autoscaler[count.index].arn
}

output "cluster-autoscaler-kiam-role-arn" {
  value = aws_iam_role.eks-cluster-autoscaler-kiam.*.arn
}

