locals {
  values_prometheus_operator = <<VALUES
prometheus-node-exporter:
  tolerations:
    - effect: NoSchedule
      operator: Exists
      key: "node-role.kubernetes.io/controller"
kubeScheduler:
  enabled: false
kubeControllerManager:
  enabled: false
grafana:
  adminPassword: ${join(",", random_string.grafana_password.*.result)}
VALUES

}

resource "kubernetes_namespace" "prometheus_operator" {
  count = var.prometheus_operator["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.prometheus_operator["namespace"]
    }

    name = var.prometheus_operator["namespace"]
  }
}

resource "random_string" "grafana_password" {
  count   = var.prometheus_operator["enabled"] ? 1 : 0
  length  = 16
  special = false
}

resource "helm_release" "prometheus_operator" {
  count         = var.prometheus_operator["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "prometheus-operator"
  chart         = "prometheus-operator"
  version       = var.prometheus_operator["chart_version"]
  timeout       = var.prometheus_operator["timeout"]
  force_update  = var.prometheus_operator["force_update"]
  recreate_pods = var.prometheus_operator["recreate_pods"]
  wait          = var.prometheus_operator["wait"]
  values = concat(
    [local.values_prometheus_operator],
    [var.prometheus_operator["extra_values"]],
  )
  namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "prometheus_operator_default_deny" {
  count = (var.prometheus_operator["enabled"] ? 1 : 0) * (var.prometheus_operator["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_namespace" {
  count = (var.prometheus_operator["enabled"] ? 1 : 0) * (var.prometheus_operator["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
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

resource "kubernetes_network_policy" "prometheus_operator_allow_ingress_nginx" {
  count = (var.prometheus_operator["enabled"] ? 1 : 0) * (var.prometheus_operator["default_network_policy"] ? 1 : 0) * (var.nginx_ingress["enabled"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]}-allow-ingress-nginx"
    namespace = kubernetes_namespace.prometheus_operator.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["grafana"]
      }
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

output "grafana_password" {
  value = random_string.grafana_password.*.result
}

