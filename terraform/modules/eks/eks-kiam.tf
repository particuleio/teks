//
// [kiam]
//
resource "aws_iam_policy" "eks-kiam-server-node" {
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name  = "terraform-eks-${var.cluster-name}-kiam-server-node"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform-eks-${var.cluster-name}-kiam-server-role"
    }
  ]
}
EOF
}

resource "aws_iam_role" "eks-kiam-server-role" {
  count       = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name        = "terraform-eks-${var.cluster-name}-kiam-server-role"
  description = "Role the Kiam Server process assumes"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.eks-node.*.arn[var.kiam["attach_to_pool"]]}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "eks-kiam-server-policy" {
  count       = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name        = "terraform-eks-${var.cluster-name}-kiam-server-policy"
  description = "Policy for the Kiam Server process"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-policy" {
  count      = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-kiam-server-role.name}"
  policy_arn = "${aws_iam_policy.eks-kiam-server-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-node" {
  count      = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  role       = "${aws_iam_role.eks-node.*.name[var.kiam["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-kiam-server-node.arn}"
}

output "kiam-server-role-arn" {
  value = "${aws_iam_role.eks-kiam-server-role.*.arn}"
}
