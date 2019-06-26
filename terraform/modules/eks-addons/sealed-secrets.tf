locals {
  values_sealed_secrets = <<VALUES
image:
  tag: ${var.sealed_secrets["version"]}
VALUES

}

resource "kubernetes_namespace" "sealed_secrets" {
  count = var.sealed_secrets["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.sealed_secrets["namespace"]
    }

    name = var.sealed_secrets["namespace"]
  }
}

resource "helm_release" "sealed_secrets" {
  count = var.sealed_secrets["enabled"] ? 1 : 0
  repository = data.helm_repository.stable.metadata[0].name
  name = "sealed-secrets"
  chart = "sealed-secrets"
  version = var.sealed_secrets["chart_version"]
  values = concat(
    [local.values_sealed_secrets],
    [var.sealed_secrets["extra_values"]],
  )
  namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "sealed_secrets_default_deny" {
  count = (var.sealed_secrets["enabled"] ? 1 : 0) * (var.sealed_secrets["default_network_policy"] ? 1 : 0)

  metadata {
    name = "${kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "sealed_secrets_allow_namespace" {
  count = (var.sealed_secrets["enabled"] ? 1 : 0) * (var.sealed_secrets["default_network_policy"] ? 1 : 0)

  metadata {
    name = "${kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.sealed_secrets.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

