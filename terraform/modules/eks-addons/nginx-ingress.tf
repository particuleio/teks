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

resource "kubernetes_network_policy" "nginx_ingress_default_deny" {
  count     = "${var.nginx_ingress["enabled"] * var.nginx_ingress["default_network_policy"]}"
  metadata {
    name      = "${var.nginx_ingress["namespace"]}-default-deny"
    namespace = "${var.nginx_ingress["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_namespace" {
  count     = "${var.nginx_ingress["enabled"] * var.nginx_ingress["default_network_policy"]}"
  metadata {
    name      = "${var.nginx_ingress["namespace"]}-allow-namespace"
    namespace = "${var.nginx_ingress["namespace"]}"
  }

  spec {
    pod_selector {}

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

resource "kubernetes_network_policy" "nginx_ingress_allow_ingress" {
  count     = "${var.nginx_ingress["enabled"] * var.nginx_ingress["default_network_policy"]}"
  metadata {
    name      = "${var.nginx_ingress["namespace"]}-allow-ingress"
    namespace = "${var.nginx_ingress["namespace"]}"
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["nginx-ingress"]
      }
    }

    ingress = [
      {
        ports = [
          {
            port     = "80"
            protocol = "TCP"
          },
          {
            port     = "443"
            protocol = "TCP"
          },
        ]

        from = [
          {
            ip_block {
              cidr = "172.30.0.0/16"
            }
          },
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "nginx_ingress_allow_monitoring" {
  count     = "${var.nginx_ingress["enabled"] * var.nginx_ingress["default_network_policy"]}"
  metadata {
    name      = "${var.nginx_ingress["namespace"]}-allow-monitoring"
    namespace = "${var.nginx_ingress["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        ports = [
          {
            port     = "metrics"
            protocol = "TCP"
          },
        ]

        from = [
          {
            namespace_selector {
              match_labels = {
                name = "monitoring"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}
