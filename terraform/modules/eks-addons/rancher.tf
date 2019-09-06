locals {
  values_rancher = <<VALUES
rancherImageTag: ${var.rancher["version"]}
VALUES
}

resource "kubernetes_namespace" "rancher" {
  count = var.rancher["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = ".*"
    }

    labels = {
      name = var.rancher["namespace"]
    }

    name = var.rancher["namespace"]
  }
}

resource "helm_release" "rancher" {
  count         = var.rancher["enabled"] ? 1 : 0
  repository    = var.rancher["channel"] == "latest" ? data.helm_repository.rancher_latest.metadata[0].name : data.helm_repository.rancher_stable.metadata[0].name
  name          = "rancher"
  chart         = "rancher"
  version       = var.rancher["chart_version"]
  timeout       = var.rancher["timeout"]
  force_update  = var.rancher["force_update"]
  recreate_pods = var.rancher["recreate_pods"]
  wait          = var.rancher["wait"]
  values        = concat([local.values_rancher], [var.rancher["extra_values"]])
  namespace     = kubernetes_namespace.rancher.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "rancher_default_deny" {
  count = (var.rancher["enabled"] ? 1 : 0) * (var.rancher["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.rancher.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.rancher.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "rancher_allow_namespace" {
  count = (var.rancher["enabled"] ? 1 : 0) * (var.rancher["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.rancher.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.rancher.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.rancher.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

