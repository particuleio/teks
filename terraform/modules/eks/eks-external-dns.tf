//
// [external-dns]
//
resource "aws_iam_policy" "eks-external-dns" {
  count  = var.external_dns["create_iam_resources"] ? 1 : var.external_dns["create_iam_resources_kiam"] ? 1 : 0
  name   = "terraform-eks-${var.cluster-name}-external-dns"
  policy = var.external_dns["iam_policy"]
}

resource "aws_iam_role_policy_attachment" "eks-external-dns" {
  count      = var.external_dns["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-node[var.cluster_autoscaler["attach_to_pool"]].name
  policy_arn = aws_iam_policy.eks-external-dns[0].arn
}

resource "aws_iam_role" "eks-external-dns-kiam" {
  name  = "terraform-eks-${var.cluster-name}-external-dns-kiam"
  count = var.external_dns["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-external-dns-kiam" {
  count      = var.external_dns["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-external-dns-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-external-dns[count.index].arn
}

output "external-dns-kiam-role-arn" {
  value = aws_iam_role.eks-external-dns-kiam.*.arn
}

