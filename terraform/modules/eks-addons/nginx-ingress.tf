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

resource "helm_release" "nginx_ingress" {
  count     = "${var.nginx_ingress["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "nginx-ingress"
  chart     = "nginx-ingress"
  version   = "${var.nginx_ingress["chart_version"]}"
  values    = ["${concat(list(var.nginx_ingress["use_nlb"] ? local.values_nginx_ingress_nlb : var.nginx_ingress["use_l7"] ? local.values_nginx_ingress_l7 : local.values_nginx_ingress_l4),list(var.nginx_ingress["extra_values"]))}"]
  namespace = "${var.nginx_ingress["namespace"]}"
}
