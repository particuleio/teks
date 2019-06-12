locals {
  values_npd = <<VALUES
image:
  tag: ${var.npd["version"]}
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/node
          operator: Exists
tolerations:
  - operator: Exists
VALUES
}

resource "helm_release" "node_problem_detector" {
  count     = "${var.npd["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name      = "node-problem-detector"
  chart     = "node-problem-detector"
  version   = "${var.npd["chart_version"]}"
  values    = ["${concat(list(local.values_npd),list(var.npd["extra_values"]))}"]
  namespace = "${var.npd["namespace"]}"
}

resource "kubernetes_network_policy" "npd_default_deny" {
  count     = "${var.npd["enabled"] * var.npd["default_network_policy"]}"
  metadata {
    name      = "${var.npd["namespace"]}-default-deny"
    namespace = "${var.npd["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "npd_allow_namespace" {
  count     = "${var.npd["enabled"] * var.npd["default_network_policy"]}"
  metadata {
    name      = "${var.npd["namespace"]}-allow-namespace"
    namespace = "${var.npd["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.npd["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}
