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
  iam.amazonaws.com/role: "${join(
  ",",
  data.terraform_remote_state.eks.*.outputs.cluster-autoscaler-kiam-role-arn[0],
)}"
VALUES

}

resource "kubernetes_namespace" "cluster_autoscaler" {
  count = var.cluster_autoscaler["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = ".*"
    }

    labels = {
      name = var.cluster_autoscaler["namespace"]
    }

    name = var.cluster_autoscaler["namespace"]
  }
}

resource "helm_release" "cluster_autoscaler" {
  count      = var.cluster_autoscaler["enabled"] ? 1 : 0
  repository = data.helm_repository.stable.metadata[0].name
  name       = "cluster-autoscaler"
  chart      = "cluster-autoscaler"
  version    = var.cluster_autoscaler["chart_version"]
  values = concat(
    [
      var.cluster_autoscaler["use_kiam"] ? local.values_cluster_autoscaler_kiam : local.values_cluster_autoscaler,
    ],
    [var.cluster_autoscaler["extra_values"]],
  )
  namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "cluster_autoscaler_default_deny" {
  count = (var.cluster_autoscaler["enabled"] ? 1 : 0) * (var.cluster_autoscaler["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cluster_autoscaler_allow_namespace" {
  count = (var.cluster_autoscaler["enabled"] ? 1 : 0) * (var.cluster_autoscaler["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.cluster_autoscaler.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

