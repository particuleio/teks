resource "aws_iam_policy" "eks-cni-metrics-helper" {
  count  = var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cni-metrics-helper"
  policy = var.cni_metrics_helper["iam_policy"]
}

resource "aws_iam_role" "eks-cni-metrics-helper-kiam" {
  name  = "tf-eks-${var.cluster-name}-cni-metrics-helper-kiam"
  count = var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cni-metrics-helper-kiam" {
  count      = var.cni_metrics_helper["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cni-metrics-helper-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cni-metrics-helper[count.index].arn
}

data "template_file" "cni_metrics_helper" {
  count    = var.cni_metrics_helper["enabled"] ? 1 : 0
  template = file("templates/cni-metrics-helper.yaml")
  vars = {
    cni_metrics_helper_role_arn = var.cni_metrics_helper["create_iam_resources_kiam"] ? aws_iam_role.eks-cni-metrics-helper-kiam[count.index].arn : ""
    cni_metrics_helper_version  = var.cni_metrics_helper["version"]
  }
}

resource "null_resource" "cni_metrics_helper" {
  count = var.cni_metrics_helper["enabled"] ? 1 : 0
  triggers = {
    always = data.template_file.cni_metrics_helper.*.rendered[count.index]
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig apply -f -<<EOF\n${data.template_file.cni_metrics_helper.*.rendered[count.index]}\nEOF"
  }

  depends_on = [
    helm_release.kiam
  ]
}
