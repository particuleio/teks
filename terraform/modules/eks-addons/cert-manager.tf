locals {
  values_cert_manager = <<VALUES
image:
  tag: ${var.cert_manager["version"]}
rbac:
  create: true
nodeSelector:
  node-role.kubernetes.io/controller: ""
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
VALUES

  values_cert_manager_kiam = <<VALUES
image:
  tag: ${var.cert_manager["version"]}
rbac:
  create: true
podAnnotations:
  iam.amazonaws.com/role: "${join(",", data.terraform_remote_state.eks.*.cert-manager-kiam-role-arn[0])}"
VALUES
}

resource "kubernetes_namespace" "cert_manager" {
  count = "${var.cert_manager["enabled"] ? 1 : 0 }"

  metadata {
    annotations {
      "iam.amazonaws.com/permitted"           = ".*"
      "certmanager.k8s.io/disable-validation" = "true"
    }

    labels {
      name = "${var.cert_manager["namespace"]}"
    }

    name = "${var.cert_manager["namespace"]}"
  }
}

data "template_file" "cluster_issuers" {
  template = "${file("templates/cert-manager-cluster-issuers.yaml")}"

  vars {
    acme_email = "${var.cert_manager["acme_email"]}"
    aws_region = "${var.aws["region"]}"
  }
}

resource "helm_release" "cert_manager" {
  depends_on = [
    "kubernetes_namespace.cert_manager",
  ]

  count      = "${var.cert_manager["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.stable.metadata.0.name}"
  name       = "cert-manager"
  chart      = "cert-manager"
  version    = "${var.cert_manager["chart_version"]}"
  values     = ["${concat(list(var.cert_manager["use_kiam"] ? local.values_cert_manager_kiam : local.values_cert_manager),list(var.cert_manager["extra_values"]))}"]
  namespace  = "${var.cert_manager["namespace"]}"
}

resource "kubernetes_network_policy" "cert_manager_default_deny" {
  count = "${var.cert_manager["enabled"] * var.cert_manager["default_network_policy"]}"

  metadata {
    name      = "${var.cert_manager["namespace"]}-default-deny"
    namespace = "${var.cert_manager["namespace"]}"
  }

  spec {
    pod_selector = {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "cert_manager_allow_namespace" {
  count = "${var.cert_manager["enabled"] * var.cert_manager["default_network_policy"]}"

  metadata {
    name      = "${var.cert_manager["namespace"]}-allow-namespace"
    namespace = "${var.cert_manager["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.cert_manager["namespace"]}"
              }
            }
          },
        ]
      },
    ]

    policy_types = ["Ingress"]
  }
}

output "cert_manager_cluster_issuers" {
  value = "${data.template_file.cluster_issuers.rendered}"
}
