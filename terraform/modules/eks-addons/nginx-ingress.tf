locals {
  values_nginx_ingress = <<VALUES
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
VALUES
}

resource "helm_release" "nginx_ingress" {
  count     = "${var.nginx_ingress["enabled"] ? 1 : 0 }"
  name      = "nginx-ingress"
  chart     = "stable/nginx-ingress"
  version   = "${var.nginx_ingress["chart_version"]}"
  values    = ["${concat(list(var.nginx_ingress["use_nlb"] ? local.values_nginx_ingress_nlb : local.values_nginx_ingress),list(var.nginx_ingress["extra_values"]))}"]
  namespace = "${var.nginx_ingress["namespace"]}"
}
