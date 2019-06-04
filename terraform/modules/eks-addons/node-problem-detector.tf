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
