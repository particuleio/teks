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
}

resource "helm_release" "external_dns" {
    depends_on = [
      "kubernetes_service_account.tiller",
      "kubernetes_cluster_role_binding.tiller"
    ]
    count = "${var.external_dns["enabled"] ? 1 : 0 }"
    name      = "external-dns"
    chart     = "stable/external-dns"
    version   = "${var.external_dns["chart_version"]}"
    values = ["${concat(list(local.values_external_dns),list(var.external_dns["extra_values"]))}"]
    namespace = "${var.external_dns["namespace"]}"
}
