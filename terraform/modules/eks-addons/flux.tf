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

resource "kubernetes_network_policy" "flux_default_deny" {
  count     = "${var.flux["enabled"] * var.flux["default_network_policy"]}"
  metadata {
    name      = "${var.flux["namespace"]}-default-deny"
    namespace = "${var.flux["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_namespace" {
  count     = "${var.flux["enabled"] * var.flux["default_network_policy"]}"
  metadata {
    name      = "${var.flux["namespace"]}-allow-namespace"
    namespace = "${var.flux["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.flux["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}
