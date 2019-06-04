locals {
  values_external_dns = <<VALUES
image:
  tag: ${var.external_dns["version"]}
provider: aws
txtPrefix: "ext-dns-"
rbac:
 create: true
nodeSelector:
  node-role.kubernetes.io/controller: ""
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
VALUES
  values_external_dns_kiam = <<VALUES
image:
  tag: ${var.external_dns["version"]}
provider: aws
txtPrefix: "ext-dns-"
rbac:
 create: true
podAnnotations:
  iam.amazonaws.com/role: "${join(",", data.terraform_remote_state.eks.*.external-dns-kiam-role-arn[0])}"
VALUES
}

resource "kubernetes_namespace" "external_dns" {
  count = "${var.external_dns["enabled"] ? 1 : 0 }"

  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    name = "${var.external_dns["namespace"]}"
  }
}

resource "helm_release" "external_dns" {
  depends_on = [
    "kubernetes_namespace.external_dns"
  ]
  count     = "${var.external_dns["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "external-dns"
  chart     = "external-dns"
  version   = "${var.external_dns["chart_version"]}"
  values    = ["${concat(list(var.external_dns["use_kiam"] ? local.values_external_dns_kiam : local.values_external_dns),list(var.external_dns["extra_values"]))}"]
  namespace = "${var.external_dns["namespace"]}"
}
