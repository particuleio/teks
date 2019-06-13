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

    labels {
      name = "${var.cluster_autoscaler["namespace"]}"
    }

    name = "${var.cluster_autoscaler["namespace"]}"
  }
}

resource "helm_release" "cluster_autoscaler" {
  depends_on = [
    "kubernetes_namespace.cluster_autoscaler",
  ]

  count      = "${var.cluster_autoscaler["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name       = "cluster-autoscaler"
  chart      = "cluster-autoscaler"
  version    = "${var.cluster_autoscaler["chart_version"]}"
  values     = ["${concat(list(var.cluster_autoscaler["use_kiam"] ? local.values_cluster_autoscaler_kiam : local.values_cluster_autoscaler),list(var.cluster_autoscaler["extra_values"]))}"]
  namespace  = "${var.cluster_autoscaler["namespace"]}"
}

resource "kubernetes_network_policy" "cluster_autoscaler_default_deny" {
  count = "${var.cluster_autoscaler["enabled"] * var.cluster_autoscaler["default_network_policy"]}"

  metadata {
    name      = "${var.cluster_autoscaler["namespace"]}-default-deny"
    namespace = "${var.cluster_autoscaler["namespace"]}"
  }

  spec {
    pod_selector = {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster_autoscaler_allow_namespace" {
  count = "${var.cluster_autoscaler["enabled"] * var.cluster_autoscaler["default_network_policy"]}"

  metadata {
    name      = "${var.cluster_autoscaler["namespace"]}-allow-namespace"
    namespace = "${var.cluster_autoscaler["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.cluster_autoscaler["namespace"]}"
              }
            }
          },
        ]
      },
    ]

    policy_types = ["Ingress"]
  }
}
