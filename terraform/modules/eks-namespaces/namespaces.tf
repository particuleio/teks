resource "kubernetes_namespace" "namespace" {
  count = length(var.namespaces)

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${var.namespaces[count.index]["kiam_allowed_regexp"]}"
    }

    labels = {
      name = var.namespaces[count.index]["name"]
    }

    name = var.namespaces[count.index]["name"]
  }
}

#resource "kubernetes_service_account" "tiller" {
#  count = "${length(var.namespaces)}"
#  metadata {
#    name = "tiller"
#    namespace = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#  }
#  automount_service_account_token = true
#}

#resource "kubernetes_role" "tiller" {
#  count = "${length(var.namespaces)}"
#  metadata {
#    name = "tiller-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#    namespace = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#  }
#  rule {
#    api_groups = ["", "batch", "extensions", "apps"]
#    resources = ["*"]
#    verbs = ["*"]
#  }
#  rule {
#    api_groups = ["monitoring.coreos.com"]
#    resources = [
#      "prometheusrules",
#      "servicemonitors"
#    ]
#    verbs = ["*"]
#  }
#}

#resource "kubernetes_role_binding" "tiller" {
#  count = "${length(var.namespaces)}"
#  metadata {
#      name = "tiller-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-binding"
#      namespace = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#  }
#  role_ref {
#      api_group = "rbac.authorization.k8s.io"
#      kind = "Role"
#      name = "${kubernetes_role.tiller.*.metadata.0.name[count.index]}"
#  }
#  subject {
#      kind = "ServiceAccount"
#      name = "${kubernetes_service_account.tiller.*.metadata.0.name[count.index]}"
#      namespace = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#  }
#
#  provisioner "local-exec" {
#    command = "helm init --kubeconfig kubeconfig --upgrade --service-account ${kubernetes_service_account.tiller.*.metadata.0.name[count.index]} --tiller-namespace ${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
#  }
#}

resource "kubernetes_role" "flux" {
  count = length(var.namespaces)

  metadata {
    name      = "flux-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps", "autoscaling"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["monitoring.coreos.com"]

    resources = [
      "prometheusrules",
      "servicemonitors",
      "podmonitors",
    ]

    verbs = ["*"]
  }

  rule {
    api_groups = ["flux.weave.works"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["bitnami.com"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["policy"]
    resources  = ["poddisruptionbudgets"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "flux" {
  count = length(var.namespaces)

  metadata {
    name      = "flux-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-binding"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.flux.*.metadata.0.name[count.index]
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }
}

resource "kubernetes_cluster_role" "flux" {
  count = length(var.namespaces)

  metadata {
    name = "flux-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
  }

  rule {
    api_groups = [""]
    resources  = ["namespaces"]
    verbs      = ["list", "get", "watch"]
  }

  rule {
    api_groups = ["apiextensions.k8s.io"]
    resources  = ["customresourcedefinitions"]
    verbs      = ["list", "get", "watch"]
  }
}

resource "kubernetes_cluster_role_binding" "flux" {
  count = length(var.namespaces)

  metadata {
    name = "flux-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-binding"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role.flux.*.metadata.0.name[count.index]
  }

  subject {
    kind      = "ServiceAccount"
    name      = "flux"
    namespace = "flux"
  }
}

resource "kubernetes_role" "namespace_admin" {
  count = length(var.namespaces)

  metadata {
    name      = "admin-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps", "autoscaling"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["monitoring.coreos.com"]

    resources = [
      "prometheusrules",
      "servicemonitors",
    ]

    verbs = ["*"]
  }

  rule {
    api_groups = ["bitnami.com"]
    resources  = ["*"]
    verbs      = ["*"]
  }

  rule {
    api_groups = ["networking.k8s.io"]
    resources  = ["*"]
    verbs      = ["*"]
  }
}

resource "kubernetes_role_binding" "namespace_admin" {
  count = length(var.namespaces)

  metadata {
    name      = "admin-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-binding"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.namespace_admin.*.metadata.0.name[count.index]
  }

  subject {
    kind      = "Group"
    name      = "admin-${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}"
    api_group = "rbac.authorization.k8s.io"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }
}

resource "kubernetes_network_policy" "namespace_default_deny" {
  count = length(var.namespaces)

  metadata {
    name      = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "namespace_allow_namespace" {
  count = length(var.namespaces)

  metadata {
    name      = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "namespace_allow_monitoring" {
  count = length(var.namespaces)

  metadata {
    name      = "${kubernetes_namespace.namespace.*.metadata.0.name[count.index]}-allow-monitoring"
    namespace = kubernetes_namespace.namespace.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      ports {
        port     = "metrics"
        protocol = "TCP"
      }

      from {
        namespace_selector {
          match_labels = {
            name = "monitoring"
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

output "eks-namespaces" {
  value = kubernetes_namespace.namespace.*.metadata.0.name
}
