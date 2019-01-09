locals {
  values_cluster_autoscaler = <<VALUES
autoDiscovery:
  clusterName: ${var.cluster_autoscaler["cluster_name"]}
awsRegion: ${var.aws["region"]}
sslCertPath: /etc/kubernetes/pki/ca.crt
rbac:
 create: true
image:
  tag: ${var.cluster_autoscaler["version"]}
nodeSelector:
  node-role.kubernetes.io/controller: ""
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
VALUES
}

resource "helm_release" "cluster_autoscaler" {
  depends_on = [
    "kubernetes_service_account.tiller",
    "kubernetes_cluster_role_binding.tiller",
  ]

  count     = "${var.cluster_autoscaler["enabled"] ? 1 : 0 }"
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  version   = "${var.cluster_autoscaler["chart_version"]}"
  values    = ["${concat(list(local.values_cluster_autoscaler),list(var.cluster_autoscaler["extra_values"]))}"]
  namespace = "${var.cluster_autoscaler["namespace"]}"
}
