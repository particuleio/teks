locals {
  values_cluster_autoscaler = <<VALUES
autoDiscovery:
  clusterName: ${var.cluster_autoscaler["cluster_name"]}
awsRegion: ${var.aws["region"]}
sslCertPath: /etc/kubernetes/pki/ca.crt
rbac:
 create: true
 pspEnabled: true
image:
  tag: ${var.cluster_autoscaler["version"]}
nodeSelector:
  node-role.kubernetes.io/controller: ""
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
VALUES
  values_cluster_autoscaler_kiam = <<VALUES
autoDiscovery:
  clusterName: ${var.cluster_autoscaler["cluster_name"]}
awsRegion: ${var.aws["region"]}
sslCertPath: /etc/kubernetes/pki/ca.crt
rbac:
 create: true
 pspEnabled: true
image:
  tag: ${var.cluster_autoscaler["version"]}
podAnnotations:
  iam.amazonaws.com/role: "${join(",", data.terraform_remote_state.eks.*.cluster-autoscaler-kiam-role-arn[0])}"
VALUES
}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count = "${var.cluster_autoscaler["enabled"] ? 1 : 0 }"

  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    name = "${var.cluster_autoscaler["namespace"]}"
  }
}

resource "helm_release" "cluster_autoscaler" {
  depends_on = [
    "kubernetes_namespace.cluster_autoscaler"
  ]
  count     = "${var.cluster_autoscaler["enabled"] ? 1 : 0 }"
  name      = "cluster-autoscaler"
  chart     = "stable/cluster-autoscaler"
  version   = "${var.cluster_autoscaler["chart_version"]}"
  values    = ["${concat(list(var.cluster_autoscaler["use_kiam"] ? local.values_cluster_autoscaler_kiam : local.values_cluster_autoscaler),list(var.cluster_autoscaler["extra_values"]))}"]
  namespace = "${var.cluster_autoscaler["namespace"]}"
}
