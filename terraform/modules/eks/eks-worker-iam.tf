//
// [default]
//
resource "aws_iam_role" "eks-node" {
  name  = "terraform-eks-${var.cluster-name}-node-pool-${var.node-pools[count.index]["name"]}"
  count = length(var.node-pools)

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
  role       = aws_iam_role.eks-node[count.index].name
  count      = length(var.node-pools)
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-node[count.index].name
  count      = length(var.node-pools)
}

resource "aws_iam_role_policy_attachment" "eks-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-node[count.index].name
  count      = length(var.node-pools)
}

resource "aws_iam_instance_profile" "eks-node" {
  name  = "terraform-eks-${var.cluster-name}-node-pool-${var.node-pools[count.index]["name"]}"
  role  = aws_iam_role.eks-node[count.index].name
  count = length(var.node-pools)
}

