locals {
  values_cert_manager_kiam = <<VALUES
image:
  tag: ${var.cert_manager["version"]}
rbac:
  create: true
podAnnotations:
  iam.amazonaws.com/role: "${var.cert_manager["create_iam_resources_kiam"] ? aws_iam_role.eks-cert-manager-kiam[0].arn : ""}"
VALUES

}

resource "aws_iam_policy" "eks-cert-manager" {
  count  = var.cert_manager["create_iam_resources_kiam"] ? 1 : 0
  name   = "tf-eks-${var.cluster-name}-cert-manager"
  policy = var.cert_manager["iam_policy"]
}

resource "aws_iam_role" "eks-cert-manager-kiam" {
  name  = "tf-eks-${var.cluster-name}-cert-manager-kiam"
  count = var.cert_manager["create_iam_resources_kiam"] ? 1 : 0

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

resource "aws_iam_role_policy_attachment" "eks-cert-manager-kiam" {
  count      = var.cert_manager["create_iam_resources_kiam"] ? 1 : 0
  role       = aws_iam_role.eks-cert-manager-kiam[count.index].name
  policy_arn = aws_iam_policy.eks-cert-manager[count.index].arn
}

resource "kubernetes_namespace" "cert_manager" {
  count = var.cert_manager["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted"           = "${aws_iam_role.eks-cert-manager-kiam[0].arn}"
      "certmanager.k8s.io/disable-validation" = "true"
    }

    labels = {
      name = var.cert_manager["namespace"]
    }

    name = var.cert_manager["namespace"]
  }
}

data "template_file" "cert_manager_crds" {
  count    = (var.cert_manager["enabled"] ? 1 : 0) * (var.cert_manager["enable_default_cluster_issuers"] ? 1 : 0)
  template = file("templates/cert-manager-crds-release-0.9.yaml")
}

resource "null_resource" "cert_manager_crds" {
  count = (var.cert_manager["enabled"] ? 1 : 0)
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig apply -f -<<EOF\n${data.template_file.cert_manager_crds.*.rendered[count.index]}\nEOF"
  }
}

resource "helm_release" "cert_manager" {
  count         = var.cert_manager["enabled"] ? 1 : 0
  repository    = data.helm_repository.jetstack.metadata[0].name
  name          = "cert-manager"
  chart         = "cert-manager"
  version       = var.cert_manager["chart_version"]
  timeout       = var.cert_manager["timeout"]
  force_update  = var.cert_manager["force_update"]
  recreate_pods = var.cert_manager["recreate_pods"]
  wait          = var.cert_manager["wait"]
  values = concat(
    [local.values_cert_manager_kiam],
    [var.cert_manager["extra_values"]],
  )
  namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]

  depends_on = [
    null_resource.cert_manager_crds,
    helm_release.kiam
  ]
}

resource "kubernetes_network_policy" "cert_manager_default_deny" {
  count = (var.cert_manager["enabled"] ? 1 : 0) * (var.cert_manager["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cert_manager_allow_namespace" {
  count = (var.cert_manager["enabled"] ? 1 : 0) * (var.cert_manager["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cert_manager.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

data "template_file" "cert_manager_cluster_issuers" {
  count    = (var.cert_manager["enabled"] ? 1 : 0) * (var.cert_manager["enable_default_cluster_issuers"] ? 1 : 0)
  template = file("templates/cert-manager-cluster-issuers.yaml")

  vars = {
    acme_email = var.cert_manager["acme_email"]
    aws_region = var.aws["region"]
  }
}

resource "null_resource" "cert_manager_cluster_issuers" {
  count = (var.cert_manager["enabled"] ? 1 : 0) * (var.cert_manager["enable_default_cluster_issuers"] ? 1 : 0)
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    command = "kubectl --kubeconfig=kubeconfig apply -f -<<EOF\n${data.template_file.cert_manager_cluster_issuers.*.rendered[count.index]}\nEOF"
  }

  depends_on = [helm_release.cert_manager]
}
