locals {
  values_prometheus_operator = <<VALUES
grafana:
  adminPassword: ${join(",", random_string.grafana_password.*.result)}
  persistence:
    enabled: true
    storageClassName: gp2
    accessModes:
      - ReadWriteOnce
    size: 10Gi

kubeScheduler:
  enabled: false

kubeControllerManager:
  enabled: false

prometheus:
  prometheusSpec:
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
prometheus-node-exporter:
  tolerations:
    - effect: NoSchedule
      operator: Exists
      key: "node-role.kubernetes.io/controller"
VALUES
}

resource "random_string" "grafana_password" {
  count     = "${var.prometheus_operator["enabled"] ? 1 : 0 }"
  length  = 16
  special = false
}

resource "helm_release" "prometheus_operator" {
  count     = "${var.prometheus_operator["enabled"] ? 1 : 0 }"
  name      = "prometheus-operator"
  chart     = "stable/prometheus-operator"
  version   = "${var.prometheus_operator["chart_version"]}"
  values    = ["${concat(list(local.values_prometheus_operator),list(var.prometheus_operator["extra_values"]))}"]
  namespace = "${var.prometheus_operator["namespace"]}"
}

output "grafana_password" {
  value = "${random_string.grafana_password.*.result}"
}
