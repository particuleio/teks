locals {
  values_flux = <<VALUES
image:
  tag: ${var.flux["version"]}
rbac:
  create: true
helmOperator:
  create: true
VALUES
}

resource "helm_release" "flux" {
  count     = "${var.flux["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.flux.metadata.0.name}"
  name      = "flux"
  chart     = "flux"
  version   = "${var.flux["chart_version"]}"
  values    = ["${concat(list(local.values_flux),list(var.flux["extra_values"]))}"]
  namespace = "${var.flux["namespace"]}"
}
