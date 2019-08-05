locals {
  values_kiam = <<VALUES
psp:
  create: false
agent:
  image:
    tag: ${var.kiam["version"]}
  host:
    interface: "eni+"
    iptables: true
  updateStrategy: "RollingUpdate"
  extraHostPathMounts:
    - name: ssl-certs
      mountPath: /etc/ssl/certs
      hostPath: /etc/pki/ca-trust/extracted/pem
      readOnly: true
  tolerations: ${var.kiam["server_use_host_network"] ? "[{'operator': 'Exists'}]" : "[]"}
server:
  service:
    targetPort: 11443
  useHostNetwork: ${var.kiam["server_use_host_network"]}
  image:
    tag: ${var.kiam["version"]}
  assumeRoleArn: ${join(",", data.terraform_remote_state.eks.*.outputs.kiam-server-role-arn[0])}
  extraHostPathMounts:
    - name: ssl-certs
      mountPath: /etc/ssl/certs
      hostPath: /etc/pki/ca-trust/extracted/pem
      readOnly: true
  extraEnv:
    AWS_DEFAULT_REGION: ${var.aws["region"]}
    AWS_ACCESS_KEY_ID: ${join(",", data.terraform_remote_state.eks.*.outputs.kiam-user-access-key-id[0], )}
    AWS_SECRET_ACCESS_KEY: ${join(",", data.terraform_remote_state.eks.*.outputs.kiam-user-secret-access-key[0], )}
VALUES

values_kiam_user = <<VALUES
server:
  extraEnv:
    AWS_DEFAULT_REGION: ${var.aws["region"]}
    AWS_ACCESS_KEY_ID: ${join(",", data.terraform_remote_state.eks.*.outputs.kiam-user-access-key-id[0], )}
    AWS_SECRET_ACCESS_KEY: ${join(",", data.terraform_remote_state.eks.*.outputs.kiam-user-secret-access-key[0], )}
VALUES
}

resource "kubernetes_namespace" "kiam" {
  count = var.kiam["enabled"] ? 1 : 0

  metadata {
    labels = {
      name = var.kiam["namespace"]
    }

    name = var.kiam["namespace"]
  }
}

resource "helm_release" "kiam" {
  count      = var.kiam["enabled"] ? 1 : 0
  repository = data.helm_repository.stable.metadata[0].name
  name       = "kiam"
  chart      = "kiam"
  version    = var.kiam["chart_version"]
  values     = concat([local.values_kiam], [var.kiam["extra_values"]])
  namespace  = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
}

resource "kubernetes_network_policy" "kiam_default_deny" {
  count = (var.kiam["enabled"] ? 1 : 0) * (var.kiam["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kiam_allow_namespace" {
  count = (var.kiam["enabled"] ? 1 : 0) * (var.kiam["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "kiam_allow_requests" {
  count = (var.kiam["enabled"] ? 1 : 0) * (var.kiam["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.kiam.*.metadata.0.name[count.index]}-allow-requests"
    namespace = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
      match_expressions {
        key      = "app"
        operator = "In"
        values   = ["kiam"]
      }

      match_expressions {
        key      = "component"
        operator = "In"
        values   = ["server"]
      }
    }

    ingress {
      ports {
        port     = "grpclb"
        protocol = "TCP"
      }

      from {
        namespace_selector {
        }
        pod_selector {
        }
      }
    }

    policy_types = ["Ingress"]
  }
}
