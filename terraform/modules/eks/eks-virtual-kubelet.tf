resource "aws_iam_role" "eks-virtual-kubelet-ecs-task" {
  name  = "terraform-eks-${var.cluster-name}-virtual-kubelet-ecs-task"
  count = "${var.virtual_kubelet["create_iam_resources"] ? 1 : 0 }"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet-ecs-task" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = "${aws_iam_role.eks-virtual-kubelet-ecs-task.*.name[count.index]}"
  count      = "${var.virtual_kubelet["create_iam_resources"] ? 1 : 0 }"
}

resource "aws_iam_role" "eks-virtual-kubelet" {
  name  = "terraform-eks-${var.cluster-name}-virtual-kubelet"
  count = "${var.virtual_kubelet["create_iam_resources"] ? 1 : 0 }"

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

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = "${aws_iam_role.eks-virtual-kubelet.*.name[count.index]}"
  count      = "${var.virtual_kubelet["create_iam_resources"] ? 1 : 0 }"
}
