locals {
  values_metrics_server = <<VALUES
image:
  tag: ${var.metrics_server["version"]}
args:
  - --logtostderr
  - --kubelet-preferred-address-types=InternalIP,ExternalIP
rbac:
  pspEnabled: true
VALUES

}

resource "kubernetes_namespace" "metrics_server" {
  count = var.metrics_server["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.metrics_server["namespace"]
    }

    name = var.metrics_server["namespace"]
  }
}

resource "helm_release" "metrics_server" {
  count         = var.metrics_server["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "metrics-server"
  chart         = "metrics-server"
  version       = var.metrics_server["chart_version"]
  timeout       = var.metrics_server["timeout"]
  force_update  = var.metrics_server["force_update"]
  recreate_pods = var.metrics_server["recreate_pods"]
  wait          = var.metrics_server["wait"]
  values = concat(
    [local.values_metrics_server],
    [var.metrics_server["extra_values"]],
  )
  namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "metrics_server_default_deny" {
  count = (var.metrics_server["enabled"] ? 1 : 0) * (var.metrics_server["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics_server_allow_namespace" {
  count = (var.metrics_server["enabled"] ? 1 : 0) * (var.metrics_server["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics_server_allow_control_plane" {
  count = (var.metrics_server["enabled"] ? 1 : 0) * (var.metrics_server["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]}-allow-control-plane"
    namespace = kubernetes_namespace.metrics_server.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["metrics-server"]
      }
    }

    ingress {
      ports {
        port     = "8443"
        protocol = "TCP"
      }

      from {
        ip_block {
          cidr = var.metrics_server["control_plane_private_cidr"]
        }
      }
      from {
        ip_block {
          cidr = var.metrics_server["control_plane_public_cidr"]
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

