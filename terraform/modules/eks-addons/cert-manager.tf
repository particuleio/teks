locals {
  values_cert_manager = <<VALUES
image:
  tag: ${var.cert_manager["version"]}
rbac:
  create: true
nodeSelector:
  node-role.kubernetes.io/controller: ""
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
VALUES
  values_cert_manager_kiam = <<VALUES
image:
  tag: ${var.cert_manager["version"]}
rbac:
  create: true
podAnnotations:
  iam.amazonaws.com/role: "${join(",", data.terraform_remote_state.eks.*.cert-manager-kiam-role-arn[0])}"
VALUES
}

resource "kubernetes_namespace" "cert_manager" {
  count = "${var.cert_manager["enabled"] ? 1 : 0 }"
  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    name = "${var.cert_manager["namespace"]}"
  }
}

data "template_file" "cluster_issuers" {
  template = "${file("templates/cert-manager-cluster-issuers.yaml")}"

  vars {
    acme_email = "${var.cert_manager["acme_email"]}"
    aws_region = "${var.aws["region"]}"
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    "kubernetes_namespace.cert_manager"
  ]
  count     = "${var.cert_manager["enabled"] ? 1 : 0 }"
  name      = "cert-manager"
  chart     = "stable/cert-manager"
  version   = "${var.cert_manager["chart_version"]}"
  values    = ["${concat(list(var.cert_manager["use_kiam"] ? local.values_cert_manager_kiam : local.values_cert_manager),list(var.cert_manager["extra_values"]))}"]
  namespace = "${var.cert_manager["namespace"]}"
}

output "cert_manager_cluster_issuers" {
  value = "${data.template_file.cluster_issuers.rendered}"
}
