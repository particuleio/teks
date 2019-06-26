#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "eks-cluster" {
  name = "terraform-eks-cluster-${var.cluster-name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_iam_role_policy_attachment" "eks-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = "${aws_iam_role.eks-cluster.name}"
}

resource "aws_security_group" "eks-cluster" {
  name        = "terraform-eks-cluster-${var.cluster-name}"
  description = "Cluster communication with worker nodes"
  vpc_id      = "${var.vpc["create"] ? join(",",aws_vpc.eks.*.id) : var.vpc["vpc_id"]}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Name = "terraform-eks-${var.cluster-name}"
  }
}

resource "aws_security_group_rule" "eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-cluster.id}"
  source_security_group_id = "${aws_security_group.eks-node.id}"
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-cluster-ingress-workstation-https" {
  cidr_blocks       = "${var.allowed_cidr_blocks}"
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port           = 443
  type              = "ingress"
}

resource "aws_cloudwatch_log_group" "eks-logs" {
  name              = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = "${var.cluster_log_retention_in_days}"
}

resource "aws_eks_cluster" "eks" {
  name     = "${var.cluster-name}"
  role_arn = "${aws_iam_role.eks-cluster.arn}"

  enabled_cluster_log_types = "${var.enabled_cluster_log_types}"

  vpc_config {
    security_group_ids      = ["${aws_security_group.eks-cluster.id}"]
    subnet_ids              = ["${split(",", var.vpc["create"] ? join(",", concat(aws_subnet.eks-private.*.id, aws_subnet.eks.*.id)) : join(",", concat(split(",", var.vpc["private_subnets_id"]),split(",", var.vpc["public_subnets_id"]))))}"]
    endpoint_private_access = "${var.endpoint_private_access}"
    endpoint_public_access  = "${var.endpoint_public_access}"
  }

  version = "${var.kubernetes_version}"

  depends_on = [
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.eks-cluster-AmazonEKSServicePolicy",
    "aws_cloudwatch_log_group.eks-logs",
  ]
}
