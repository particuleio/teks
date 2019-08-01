locals {
  values_istio      = <<VALUES
VALUES
  values_istio_init = <<VALUES
VALUES
}

resource "kubernetes_namespace" "istio" {
  count = var.istio["enabled"] ? 1 : 0

  metadata {
    annotations = {
    }

    labels = {
      name = var.istio["namespace"]
    }

    name = var.istio["namespace"]
  }
}

resource "helm_release" "istio-init" {
  count      = var.istio["enabled_init"] ? 1 : 0
  repository = data.helm_repository.istio.metadata[0].name
  name       = "istio-init"
  chart      = "istio-init"
  version    = var.istio["chart_version_init"]
  values     = concat([local.values_istio], [var.istio["extra_values_init"]])
  namespace  = kubernetes_namespace.istio.*.metadata.0.name[count.index]
}

resource "helm_release" "istio" {
  count      = var.istio["enabled"] ? 1 : 0
  repository = data.helm_repository.istio.metadata[0].name
  name       = "istio"
  chart      = "istio"
  version    = var.istio["chart_version"]
  values     = concat([local.values_istio], [var.istio["extra_values"]])
  namespace  = kubernetes_namespace.istio.*.metadata.0.name[count.index]

  depends_on = [helm_release.istio-init]
}

resource "kubernetes_network_policy" "istio_default_deny" {
  count = (var.istio["enabled"] ? 1 : 0) * (var.istio["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.istio.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.istio.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "istio_allow_namespace" {
  count = (var.istio["enabled"] ? 1 : 0) * (var.istio["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.istio.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.istio.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.istio.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

