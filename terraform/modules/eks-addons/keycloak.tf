locals {
  values_keycloak = <<VALUES
image:
  tag: ${var.keycloak["version"]}
VALUES

}

resource "kubernetes_namespace" "keycloak" {
  count = var.keycloak["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.keycloak["namespace"]
    }

    name = var.keycloak["namespace"]
  }
}

resource "helm_release" "keycloak" {
  count         = var.keycloak["enabled"] ? 1 : 0
  repository    = data.helm_repository.codecentric.metadata[0].name
  name          = "keycloak"
  chart         = "keycloak"
  version       = var.keycloak["chart_version"]
  timeout       = var.keycloak["timeout"]
  force_update  = var.keycloak["force_update"]
  recreate_pods = var.keycloak["recreate_pods"]
  wait          = var.keycloak["wait"]
  values = concat(
    [local.values_keycloak],
    [var.keycloak["extra_values"]],
  )
  namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "keycloak_default_deny" {
  count = (var.keycloak["enabled"] ? 1 : 0) * (var.keycloak["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.keycloak.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "keycloak_allow_namespace" {
  count = (var.keycloak["enabled"] ? 1 : 0) * (var.keycloak["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.keycloak.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.keycloak.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

