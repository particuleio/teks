locals {
  values_kong = <<VALUES
image:
  tag: ${var.kong["version"]}
ingressController:
  enabled: true
postgresql:
  enabled: false
env:
  database: "off"
admin:
  type: ClusterIP
VALUES
}

resource "kubernetes_namespace" "kong" {
  count = var.kong["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.kong["namespace"]
    }

    name = var.kong["namespace"]
  }
}

resource "helm_release" "kong" {
  count         = var.kong["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "kong"
  chart         = "kong"
  version       = var.kong["chart_version"]
  timeout       = var.kong["timeout"]
  force_update  = var.kong["force_update"]
  recreate_pods = var.kong["recreate_pods"]
  wait          = var.kong["wait"]
  values = concat(
    [local.values_kong],
    [var.kong["extra_values"]],
  )
  namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "kong_default_deny" {
  count = (var.kong["enabled"] ? 1 : 0) * (var.kong["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kong_allow_namespace" {
  count = (var.kong["enabled"] ? 1 : 0) * (var.kong["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kong.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kong_allow_ingress" {
  count = (var.kong["enabled"] ? 1 : 0) * (var.kong["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-ingress"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["kong"]
      }
    }

    ingress {
      ports {
        port     = "8000"
        protocol = "TCP"
      }
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      from {
        ip_block {
          cidr = var.kong["ingress_cidr"]
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kong_allow_monitoring" {
  count = (var.kong["enabled"] ? 1 : 0) * (var.kong["default_network_policy"] ? 1 : 0) * (var.prometheus_operator["enabled"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kong.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.kong.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "metrics"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

