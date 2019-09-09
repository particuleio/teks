locals {
  values_fluentd_cloudwatch_kiam = <<VALUES
image:
  tag: ${var.fluentd_cloudwatch["version"]}
rbac:
  create: true
nodeSelector:
  node-role.kubernetes.io/node: ""
tolerations:
  - operator: Exists
awsRole: "${aws_iam_role.eks-fluentd-cloudwatch-kiam[0].arn}"
awsRegion: "${var.aws["region"]}"
logGroupName: "${aws_cloudwatch_log_group.eks-fluentd-cloudwatch-log-group[0].name}"
extraVars:
  - "{ name: FLUENT_UID, value: '0' }"
updateStrategy:
  type: RollingUpdate
VALUES

}

resource "aws_cloudwatch_log_group" "eks-fluentd-cloudwatch-log-group" {
  count             = var.fluentd_cloudwatch["enabled"] ? 1 : 0
  name              = "/aws/eks/${var.cluster-name}/containers"
  retention_in_days = var.fluentd_cloudwatch["containers_log_retention_in_days"]
}

resource "aws_iam_policy" "eks-fluentd-cloudwatch" {
  count  = var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-fluentd-cloudwatch"
  policy = var.fluentd_cloudwatch["iam_policy"]
}

resource "aws_iam_role" "eks-fluentd-cloudwatch-kiam" {
  name  = "tf-eks-${var.cluster-name}-fluentd-cloudwatch-kiam"
  count = var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-fluentd-cloudwatch-kiam" {
  count      = var.fluentd_cloudwatch["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-fluentd-cloudwatch-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-fluentd-cloudwatch[count.index].arn
}

resource "kubernetes_namespace" "fluentd_cloudwatch" {
  count = var.fluentd_cloudwatch["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${aws_iam_role.eks-fluentd-cloudwatch-kiam[0].arn}"
    }

    labels = {
      name = var.fluentd_cloudwatch["namespace"]
    }

    name = var.fluentd_cloudwatch["namespace"]
  }
}

resource "helm_release" "fluentd_cloudwatch" {
  count         = var.fluentd_cloudwatch["enabled"] ? 1 : 0
  repository    = data.helm_repository.incubator.metadata[0].name
  name          = "fluentd-cloudwatch"
  chart         = "fluentd-cloudwatch"
  version       = var.fluentd_cloudwatch["chart_version"]
  timeout       = var.fluentd_cloudwatch["timeout"]
  force_update  = var.fluentd_cloudwatch["force_update"]
  recreate_pods = var.fluentd_cloudwatch["recreate_pods"]
  wait          = var.fluentd_cloudwatch["wait"]
  values = concat(
    [local.values_fluentd_cloudwatch_kiam],
    [var.fluentd_cloudwatch["extra_values"]],
  )
  namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "fluentd_cloudwatch_default_deny" {
  count = (var.fluentd_cloudwatch["enabled"] ? 1 : 0) * (var.fluentd_cloudwatch["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "fluentd_cloudwatch_allow_namespace" {
  count = (var.fluentd_cloudwatch["enabled"] ? 1 : 0) * (var.fluentd_cloudwatch["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.fluentd_cloudwatch.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

