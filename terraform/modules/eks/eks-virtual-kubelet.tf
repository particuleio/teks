resource "aws_iam_role" "eks-virtual-kubelet-ecs-task" {
  name  = "terraform-eks-${var.cluster-name}-virtual-kubelet-ecs-task"
  count = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet-ecs-task" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.eks-virtual-kubelet-ecs-task[count.index].name
  count      = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0
}

resource "aws_iam_role" "eks-virtual-kubelet" {
  name  = "terraform-eks-${var.cluster-name}-virtual-kubelet"
  count = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.eks-virtual-kubelet[count.index].name
  count      = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0
}

resource "aws_cloudwatch_log_group" "eks-virtual-kubelet" {
  name  = "eks-cluster-${var.cluster-name}-${var.virtual_kubelet["cloudwatch_log_group"]}"
  count = var.virtual_kubelet["create_cloudwatch_log_group"] ? 1 : 0

  tags = {
    Environment = "terraform-eks-${var.cluster-name}"
    Application = "virtual-kubelet"
  }
}

output "eks-virtual-kubelet-role-arn" {
  value = aws_iam_role.eks-virtual-kubelet.*.arn
}

output "eks-virtual-kubelet-ecs-task-role-arn" {
  value = aws_iam_role.eks-virtual-kubelet-ecs-task.*.arn
}

output "eks-virtual-kubelet-cloudwatch-log-group" {
  value = aws_cloudwatch_log_group.eks-virtual-kubelet.*.name
}

