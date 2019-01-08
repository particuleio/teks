//
// [default]
//
resource "aws_iam_role" "eks-node" {
  name  = "terraform-eks-${var.cluster-name}-node-pool-${lookup(var.node-pools[count.index],"name")}"
  count = "${length(var.node-pools)}"

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
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.eks-node.*.name[count.index]}"
  count      = "${length(var.node-pools)}"
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.eks-node.*.name[count.index]}"
  count      = "${length(var.node-pools)}"
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.eks-node.*.name[count.index]}"
  count      = "${length(var.node-pools)}"
}

resource "aws_iam_instance_profile" "eks-node" {
  name  = "terraform-eks-${var.cluster-name}-node-pool-${lookup(var.node-pools[count.index],"name")}"
  role  = "${aws_iam_role.eks-node.*.name[count.index]}"
  count = "${length(var.node-pools)}"
}

//
// [cluster-autoscaler]
//
resource "aws_iam_policy" "eks-cluster-autoscaler" {
  count = "${var.cluster_autoscaler["create_iam_resources"] ? 1 : 0 }"
  name = "terraform-eks-${var.cluster-name}-cluster-autoscaler"
  policy = "${var.cluster_autoscaler["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler" {
  count = "${var.cluster_autoscaler["create_iam_resources"] ? 1 : 0 }"
  role = "${aws_iam_role.eks-node.*.name[var.cluster_autoscaler["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-cluster-autoscaler.arn}"
}

//
// [external-dns]
//
resource "aws_iam_policy" "eks-external-dns" {
  count = "${var.external_dns["create_iam_resources"] ? 1 : 0 }"
  name  = "terraform-eks-${var.cluster-name}-external-dns"
  policy = "${var.external_dns["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-external-dns" {
  count = "${var.external_dns["create_iam_resources"] ? 1 : 0 }"
  role = "${aws_iam_role.eks-node.*.name[var.cluster_autoscaler["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-external-dns.arn}"
}

//
// [cert-manager]
//
resource "aws_iam_policy" "eks-cert-manager" {
  count = "${var.cert_manager["create_iam_resources"] ? 1 : 0 }"
  name  = "terraform-eks-${var.cluster-name}-cert-manager"
  policy = "${var.cert_manager["iam_policy"]}"
}

resource "aws_iam_role_policy_attachment" "eks-cert-manager" {
  count = "${var.cert_manager["create_iam_resources"] ? 1 : 0 }"
  role = "${aws_iam_role.eks-node.*.name[var.cert_manager["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-cert-manager.arn}"
}

//
// [kiam]
//
resource "aws_iam_policy" "eks-kiam-server-node" {
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name = "terraform-eks-${var.cluster-name}-kiam-server-node"
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
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name = "terraform-eks-${var.cluster-name}-kiam-server-role"
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
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  name = "terraform-eks-${var.cluster-name}-kiam-server-policy"
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
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  role = "${aws_iam_role.eks-kiam-server-role.name}"
  policy_arn = "${aws_iam_policy.eks-kiam-server-policy.arn}"
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-node" {
  count = "${var.kiam["create_iam_resources"] ? 1 : 0 }"
  role = "${aws_iam_role.eks-node.*.name[var.kiam["attach_to_pool"]]}"
  policy_arn = "${aws_iam_policy.eks-kiam-server-node.arn}"
}

output "kiam-server-role-arn" {
  value = "${aws_iam_role.eks-kiam-server-role.*.arn}"
}
