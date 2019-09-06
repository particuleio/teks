locals {
  values_cluster_autoscaler_kiam = <<VALUES
autoDiscovery:
  clusterName: ${var.cluster_autoscaler["cluster_name"]}
awsRegion: ${var.aws["region"]}
sslCertPath: /etc/kubernetes/pki/ca.crt
rbac:
 create: true
 pspEnabled: true
image:
  tag: ${var.cluster_autoscaler["version"]}
podAnnotations:
  iam.amazonaws.com/role: "${aws_iam_role.eks-cluster-autoscaler-kiam[0].arn}"
VALUES

}

resource "aws_iam_policy" "eks-cluster-autoscaler" {
  count  = var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cluster-autoscaler"
  policy = var.cluster_autoscaler["iam_policy"]
}

resource "aws_iam_role" "eks-cluster-autoscaler-kiam" {
  name  = "tf-eks-${var.cluster-name}-cluster-autoscaler-kiam"
  count = var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cluster-autoscaler-kiam" {
  count      = var.cluster_autoscaler["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cluster-autoscaler-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cluster-autoscaler[count.index].arn
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count = var.cluster_autoscaler["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${aws_iam_role.eks-cluster-autoscaler-kiam[0].arn}"
    }

    labels = {
      name = var.cluster_autoscaler["namespace"]
    }

    name = var.cluster_autoscaler["namespace"]
  }
}

resource "helm_release" "cluster_autoscaler" {
  count         = var.cluster_autoscaler["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "cluster-autoscaler"
  chart         = "cluster-autoscaler"
  version       = var.cluster_autoscaler["chart_version"]
  timeout       = var.cluster_autoscaler["timeout"]
  force_update  = var.cluster_autoscaler["force_update"]
  recreate_pods = var.cluster_autoscaler["recreate_pods"]
  wait          = var.cluster_autoscaler["wait"]
  values = concat(
    [local.values_cluster_autoscaler_kiam],
    [var.cluster_autoscaler["extra_values"]],
  )
  namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "cluster_autoscaler_default_deny" {
  count = (var.cluster_autoscaler["enabled"] ? 1 : 0) * (var.cluster_autoscaler["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster_autoscaler_allow_namespace" {
  count = (var.cluster_autoscaler["enabled"] ? 1 : 0) * (var.cluster_autoscaler["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
