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

output "grafana_password" {
  value = "${random_string.grafana_password.*.result}"
}
