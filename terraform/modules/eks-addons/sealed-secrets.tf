locals {
  values_sealed_secrets = <<VALUES
image:
  tag: ${var.sealed_secrets["version"]}
VALUES
}

resource "helm_release" "sealed_secrets" {
  count      = "${var.sealed_secrets["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name       = "sealed-secrets"
  chart      = "sealed-secrets"
  version    = "${var.sealed_secrets["chart_version"]}"
  values     = ["${concat(list(local.values_sealed_secrets),list(var.sealed_secrets["extra_values"]))}"]
  namespace  = "${var.sealed_secrets["namespace"]}"
}

resource "kubernetes_network_policy" "sealed_secrets_default_deny" {
  count = "${var.sealed_secrets["enabled"] * var.sealed_secrets["default_network_policy"]}"

  metadata {
    name      = "${var.sealed_secrets["namespace"]}-default-deny"
    namespace = "${var.sealed_secrets["namespace"]}"
  }

  spec {
    pod_selector = {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "sealed_secrets_allow_namespace" {
  count = "${var.sealed_secrets["enabled"] * var.sealed_secrets["default_network_policy"]}"

  metadata {
    name      = "${var.sealed_secrets["namespace"]}-allow-namespace"
    namespace = "${var.sealed_secrets["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.sealed_secrets["namespace"]}"
              }
            }
          },
        ]
      },
    ]

    policy_types = ["Ingress"]
  }
}
