locals {
  values_flux = <<VALUES
image:
  tag: ${var.flux["version"]}
rbac:
  create: true
helmOperator:
  create: true
additionalArgs:
  - --k8s-allow-namespace=${var.flux["allowed_namespaces"]}
VALUES

}

resource "kubernetes_namespace" "flux" {
  count = var.flux["enabled"] ? 1 : 0

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = ".*"
    }

    labels = {
      name = var.flux["namespace"]
    }

    name = var.flux["namespace"]
  }
}

resource "kubernetes_role" "flux" {
  count = var.flux["enabled"] ? 1 : 0

  metadata {
    name = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  rule {
    api_groups = ["", "batch", "extensions", "apps"]
    resources = ["*"]
    verbs = ["*"]
  }
}

resource "kubernetes_role_binding" "flux" {
  count = var.flux["enabled"] ? 1 : 0

  metadata {
    name = "flux-${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-binding"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind = "Role"
    name = kubernetes_role.flux.*.metadata.0.name[count.index]
  }

  subject {
    kind = "ServiceAccount"
    name = "flux"
    namespace = "flux"
  }
}

resource "helm_release" "flux" {
  count = var.flux["enabled"] ? 1 : 0
  repository = data.helm_repository.flux.metadata[0].name
  name = "flux"
  chart = "flux"
  version = var.flux["chart_version"]
  values = concat([local.values_flux], [var.flux["extra_values"]])
  namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "flux_default_deny" {
  count = (var.flux["enabled"] ? 1 : 0) * (var.flux["default_network_policy"] ? 1 : 0)

  metadata {
    name = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "flux_allow_namespace" {
  count = (var.flux["enabled"] ? 1 : 0) * (var.flux["default_network_policy"] ? 1 : 0)

  metadata {
    name = "${kubernetes_namespace.flux.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.flux.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.flux.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

