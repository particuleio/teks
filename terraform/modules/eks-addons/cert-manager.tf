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
      "kubernetes_service_account.tiller",
      "kubernetes_cluster_role_binding.tiller"
    ]
    count = "${var.cert_manager["enabled"] ? 1 : 0 }"
    name      = "cert-manager"
    chart     = "stable/cert-manager"
    version   = "${var.cert_manager["chart_version"]}"
    values = ["${concat(list(local.values_cert_manager),list(var.cert_manager["extra_values"]))}"]
    namespace = "${var.cert_manager["namespace"]}"
}

output "cert_manager_cluster_issuers" {
  value = "${data.template_file.cluster_issuers.rendered}"
}
