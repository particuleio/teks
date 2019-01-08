resource "aws_security_group" "eks-node" {
  name        = "terraform-eks-node-${var.cluster-name}"
  description = "Security group for all nodes in the cluster"
  vpc_id      = "${aws_vpc.eks.id}"

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${
    map(
     "Name", "terraform-eks-node-${var.cluster-name}",
     "kubernetes.io/cluster/${var.cluster-name}", "owned",
    )
  }"
}

resource "aws_security_group_rule" "eks-node-ingress-self" {
  description              = "Allow node to communicate with each other"
  from_port                = 0
  protocol                 = "-1"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${aws_security_group.eks-node.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port                  = 65535
  type                     = "ingress"
}

resource "aws_security_group_rule" "eks-node-ingress-cluster-443" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane for metrics server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = "${aws_security_group.eks-node.id}"
  source_security_group_id = "${aws_security_group.eks-cluster.id}"
  to_port                  = 443
  type                     = "ingress"
}
