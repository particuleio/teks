locals {
  values_sealed_secrets = <<VALUES
image:
  tag: ${var.sealed_secrets["version"]}
VALUES
}

resource "helm_release" "sealed_secrets" {
  count     = "${var.sealed_secrets["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "sealed-secrets"
  chart     = "sealed-secrets"
  version   = "${var.sealed_secrets["chart_version"]}"
  values    = ["${concat(list(local.values_sealed_secrets),list(var.sealed_secrets["extra_values"]))}"]
  namespace = "${var.sealed_secrets["namespace"]}"
}
