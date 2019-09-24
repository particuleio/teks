locals {
  values_external_dns_kiam = <<VALUES
image:
  tag: ${var.external_dns["version"]}
provider: aws
txtPrefix: "ext-dns-"
rbac:
 create: true
 pspEnabled: true
podAnnotations:
  iam.amazonaws.com/role: "${aws_iam_role.eks-external-dns-kiam[0].arn}"
VALUES

}

resource "aws_iam_policy" "eks-external-dns" {
  count  = var.external_dns["create_iam_resources_kiam"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-external-dns"
  policy = var.external_dns["iam_policy"]
}

resource "aws_iam_role" "eks-external-dns-kiam" {
  name  = "terraform-eks-${var.cluster-name}-external-dns-kiam"
  count = var.external_dns["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-external-dns-kiam" {
  count      = var.external_dns["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-external-dns-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-external-dns[count.index].arn
}

resource "kubernetes_namespace" "external_dns" {
  count = var.external_dns["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${aws_iam_role.eks-external-dns-kiam[0].arn}"
    }

    labels = {
      name = var.external_dns["namespace"]
    }

    name = var.external_dns["namespace"]
  }
}

resource "helm_release" "external_dns" {
  count         = var.external_dns["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "external-dns"
  chart         = "external-dns"
  version       = var.external_dns["chart_version"]
  timeout       = var.external_dns["timeout"]
  force_update  = var.external_dns["force_update"]
  recreate_pods = var.external_dns["recreate_pods"]
  wait          = var.external_dns["wait"]
  values = concat(
    [local.values_external_dns_kiam],
    [var.external_dns["extra_values"]],
  )
  namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]

  depends_on = [
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "external_dns_default_deny" {
  count = (var.external_dns["enabled"] ? 1 : 0) * (var.external_dns["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.external_dns.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "external_dns_allow_namespace" {
  count = (var.external_dns["enabled"] ? 1 : 0) * (var.external_dns["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.external_dns.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.external_dns.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

