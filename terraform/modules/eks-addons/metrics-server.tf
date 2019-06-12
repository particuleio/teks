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

resource "helm_release" "metrics_server" {
  count     = "${var.metrics_server["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "metrics-server"
  chart     = "metrics-server"
  version   = "${var.metrics_server["chart_version"]}"
  values    = ["${concat(list(local.values_metrics_server),list(var.metrics_server["extra_values"]))}"]
  namespace = "${var.metrics_server["namespace"]}"
}

resource "kubernetes_network_policy" "metrics_server_default_deny" {
  count     = "${var.metrics_server["enabled"] * var.metrics_server["default_network_policy"]}"
  metadata {
    name      = "${var.metrics_server["namespace"]}-default-deny"
    namespace = "${var.metrics_server["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "metrics_server_allow_namespace" {
  count     = "${var.metrics_server["enabled"] * var.metrics_server["default_network_policy"]}"
  metadata {
    name      = "${var.metrics_server["namespace"]}-allow-namespace"
    namespace = "${var.metrics_server["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.metrics_server["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}
