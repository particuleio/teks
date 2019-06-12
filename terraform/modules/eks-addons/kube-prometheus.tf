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

resource "random_string" "grafana_password" {
  count     = "${var.prometheus_operator["enabled"] ? 1 : 0 }"
  length  = 16
  special = false
}

resource "helm_release" "prometheus_operator" {
  count     = "${var.prometheus_operator["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "prometheus-operator"
  chart     = "prometheus-operator"
  version   = "${var.prometheus_operator["chart_version"]}"
  values    = ["${concat(list(local.values_prometheus_operator),list(var.prometheus_operator["extra_values"]))}"]
  namespace = "${var.prometheus_operator["namespace"]}"
}

resource "kubernetes_network_policy" "prometheus_operator_default_deny" {
  count     = "${var.prometheus_operator["enabled"] * var.prometheus_operator["default_network_policy"]}"
  metadata {
    name      = "${var.prometheus_operator["namespace"]}-default-deny"
    namespace = "${var.prometheus_operator["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_namespace" {
  count     = "${var.prometheus_operator["enabled"] * var.prometheus_operator["default_network_policy"]}"
  metadata {
    name      = "${var.prometheus_operator["namespace"]}-allow-namespace"
    namespace = "${var.prometheus_operator["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.prometheus_operator["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "prometheus_operator_allow_ingress_nginx" {
  count     = "${var.prometheus_operator["enabled"] * var.prometheus_operator["default_network_policy"]}"
  metadata {
    name      = "${var.prometheus_operator["namespace"]}-allow-ingress-nginx"
    namespace = "${var.prometheus_operator["namespace"]}"
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["grafana"]
      }
    }

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.nginx_ingress["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}

output "grafana_password" {
  value = "${random_string.grafana_password.*.result}"
}
