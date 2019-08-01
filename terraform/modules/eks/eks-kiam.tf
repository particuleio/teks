//
// [kiam]
//
resource "aws_iam_policy" "eks-kiam-server-node" {
  count = var.kiam["create_iam_resources"] ? 1 : 0
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
  count       = var.kiam["create_iam_resources"] ? 1 : 0
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
        "AWS": [
          "${var.kiam["attach_to_pool"] != null ? aws_iam_role.eks-node[var.kiam["attach_to_pool"]].arn : var.kiam["create_iam_user"] ? aws_iam_user.eks-kiam-user[0].arn : ""}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "eks-kiam-server-policy" {
  count       = var.kiam["create_iam_resources"] ? 1 : 0
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
  count      = var.kiam["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-kiam-server-role[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-policy[0].arn
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-node" {
  count      = var.kiam["create_iam_resources"] ? var.kiam["attach_to_pool"] != null ? 1 : 0 : 0
  role       = aws_iam_role.eks-node[var.kiam["attach_to_pool"]].name
  policy_arn = aws_iam_policy.eks-kiam-server-node[0].arn
}

resource "aws_iam_user" "eks-kiam-user" {
  count = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  name  = "terraform-eks-${var.cluster-name}-kiam-user"
}

resource "aws_iam_access_key" "eks-kiam-user-key" {
  count = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  user  = aws_iam_user.eks-kiam-user[0].name
}

resource "aws_iam_user_policy_attachment" "eks-kiam-user" {
  count      = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  user       = aws_iam_user.eks-kiam-user[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-node[0].arn
}

output "kiam-server-role-arn" {
  value = aws_iam_role.eks-kiam-server-role.*.arn
}

output "kiam-user-access-key-id" {
  value = aws_iam_access_key.eks-kiam-user-key.*.id
}

output "kiam-user-secret-access-key" {
  value = aws_iam_access_key.eks-kiam-user-key.*.secret
}
