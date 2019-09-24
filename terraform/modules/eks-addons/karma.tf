locals {
  values_karma = <<VALUES
image:
  tag: ${var.karma["version"]}
VALUES

}

resource "kubernetes_namespace" "karma" {
  count = var.karma["enabled"] && var.karma["create_ns"] ? 1 : 0

  metadata {
    labels = {
      name = var.karma["namespace"]
    }

    name = var.karma["namespace"]
  }
}

resource "helm_release" "karma" {
  count      = var.karma["enabled"] ? 1 : 0
  repository = data.helm_repository.stable.metadata[0].name
  name       = "karma"
  chart      = "karma"
  version    = var.karma["chart_version"]
  timeout       = var.karma["timeout"]
  force_update  = var.karma["force_update"]
  recreate_pods = var.karma["recreate_pods"]
  wait          = var.karma["wait"]
  values     = concat(
    [local.values_karma],
    [var.karma["extra_values"]],
  )
  namespace  = var.karma["namespace"]
}

resource "kubernetes_network_policy" "karma_default_deny" {
  count = (var.karma["create_ns"] ? 1 : 0) * (var.karma["enabled"] ? 1 : 0) * (var.karma["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.karma.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.karma.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "karma_allow_namespace" {
  count = (var.karma["create_ns"] ? 1 : 0) * (var.karma["enabled"] ? 1 : 0) * (var.karma["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.karma.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.karma.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.karma.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

