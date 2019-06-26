locals {
  values_nginx_ingress_l4 = <<VALUES
controller:
  kind: "DaemonSet"
  daemonset:
    useHostPort: true
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "true"
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

  values_nginx_ingress_nlb = <<VALUES
controller:
  kind: "DaemonSet"
  daemonset:
    useHostPort: true
  service:
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
    externalTrafficPolicy: "Local"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "false"
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

values_nginx_ingress_l7 = <<VALUES
controller:
  kind: "DaemonSet"
  daemonset:
    useHostPort: true
  service:
    targetPorts:
      http: http
      https: http
    annotations:
      service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
      service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "https"
      service.beta.kubernetes.io/aws-load-balancer-connection-idle-timeout: "3600"
    externalTrafficPolicy: "Cluster"
  publishService:
    enabled: true
  config:
    use-proxy-protocol: "false"
    use-forwarded-headers: "true"
    proxy-real-ip-cidr: "0.0.0.0/0"
defaultBackend:
  replicaCount: 2
podSecurityPolicy:
  enabled: true
VALUES

}

resource "kubernetes_namespace" "nginx_ingress" {
count = var.nginx_ingress["enabled"] ? 1 : 0

metadata {
labels = {
name = var.nginx_ingress["namespace"]
}

name = var.nginx_ingress["namespace"]
}
}

resource "helm_release" "nginx_ingress" {
count = var.nginx_ingress["enabled"] ? 1 : 0
repository = data.helm_repository.stable.metadata[0].name
name = "nginx-ingress"
chart = "nginx-ingress"
version = var.nginx_ingress["chart_version"]
values = concat(
[
var.nginx_ingress["use_nlb"] ? local.values_nginx_ingress_nlb : var.nginx_ingress["use_l7"] ? local.values_nginx_ingress_l7 : local.values_nginx_ingress_l4,
],
[var.nginx_ingress["extra_values"]],
)
namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "nginx_ingress_default_deny" {
  count = (var.nginx_ingress["enabled"] ? 1 : 0) * (var.nginx_ingress["default_network_policy"] ? 1 : 0)

metadata {
name = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-default-deny"
namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
}

spec {
pod_selector {
}
policy_types = ["Ingress"]
}
}

resource "kubernetes_network_policy" "nginx_ingress_allow_namespace" {
  count = (var.nginx_ingress["enabled"] ? 1 : 0) * (var.nginx_ingress["default_network_policy"] ? 1 : 0)

metadata {
name = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-namespace"
namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
}

spec {
pod_selector {
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

resource "kubernetes_network_policy" "nginx_ingress_allow_ingress" {
  count = (var.nginx_ingress["enabled"] ? 1 : 0) * (var.nginx_ingress["default_network_policy"] ? 1 : 0)

metadata {
name = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-ingress"
namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
}

spec {
pod_selector {
match_expressions {
key = "app"
operator = "In"
values = ["nginx-ingress"]
}
}

ingress {
ports {
port = "80"
protocol = "TCP"
}
ports {
port = "443"
protocol = "TCP"
}

from {
ip_block {
cidr = var.nginx_ingress["ingress_cidr"]
}
}
}

policy_types = ["Ingress"]
}
}

resource "kubernetes_network_policy" "nginx_ingress_allow_monitoring" {
  count = (var.nginx_ingress["enabled"] ? 1 : 0) * (var.nginx_ingress["default_network_policy"] ? 1 : 0) * (var.prometheus_operator["enabled"] ? 1 : 0)

metadata {
name = "${kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]}-allow-monitoring"
namespace = kubernetes_namespace.nginx_ingress.*.metadata.0.name[count.index]
}

spec {
pod_selector {
}

ingress {
ports {
port = "metrics"
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

