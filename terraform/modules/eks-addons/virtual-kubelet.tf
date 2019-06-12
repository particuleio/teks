resource "kubernetes_namespace" "virtual-kubelet" {
  count = "${var.virtual_kubelet["enabled"] ? 1 : 0 }"

  depends_on = [
    "helm_release.kiam",
  ]

  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    labels {
      name = "${var.virtual_kubelet["namespace"]}"
    }

    name = "${var.virtual_kubelet["namespace"]}"
  }
}

resource "kubernetes_config_map" "virtual-kubelet" {
  count = "${var.virtual_kubelet["enabled"] ? 1 : 0 }"

  depends_on = [
    "helm_release.kiam",
  ]

  metadata {
    name      = "virtual-kubelet-fargate-conf"
    namespace = "${var.virtual_kubelet["namespace"]}"
  }

  data {
    fargate.toml = <<DATA
Region = "${var.aws["region"]}"
ClusterName = "${var.virtual_kubelet["fargate_cluster_name"]}"
Subnets = ["${join("\",\"", data.terraform_remote_state.eks.vpc-private-subnets)}"]
SecurityGroups = ["${data.terraform_remote_state.eks.eks-node-sg}"]
AssignPublicIPv4Address = false
ExecutionRoleArn = "${data.terraform_remote_state.eks.eks-virtual-kubelet-ecs-task-role-arn[0]}"
CloudWatchLogGroupName = "${data.terraform_remote_state.eks.eks-virtual-kubelet-cloudwatch-log-group[0]}"
PlatformVersion = "${var.virtual_kubelet["platformversion"]}"
OperatingSystem = "${var.virtual_kubelet["operatingsystem"]}"
CPU = "${var.virtual_kubelet["cpu"]}"
Memory = "${var.virtual_kubelet["memory"]}"
Pods = "${var.virtual_kubelet["pods"]}"
DATA
  }
}

resource "kubernetes_deployment" "virtual-kubelet" {
  count = "${var.virtual_kubelet["enabled"] ? 1 : 0 }"

  metadata {
    name      = "virtual-kubelet"
    namespace = "${var.virtual_kubelet["namespace"]}"

    labels {
      app = "virtual-kubelet"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels {
        app = "virtual-kubelet"
      }
    }

    template {
      metadata {
        labels {
          app = "virtual-kubelet"
        }

        annotations {
          "iam.amazonaws.com/role" = "${join(",", data.terraform_remote_state.eks.*.eks-virtual-kubelet-role-arn[0])}"
        }
      }

      spec {
        container {
          image = "microsoft/virtual-kubelet:${var.virtual_kubelet["version"]}"
          name  = "virtual-kubelet"

          args = [
            "--kubeconfig=/etc/kubeconfig",
            "--provider=aws",
            "--provider-config=/etc/fargate/fargate.toml",
          ]

          env {
            name  = "KUBELET_PORT"
            value = "10250"
          }

          env {
            name = "VKUBELET_POD_IP"

            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "status.podIP"
              }
            }
          }

          volume_mount {
            mount_path = "/etc/kubeconfig"
            name       = "kubeconfig"
          }

          volume_mount {
            mount_path = "/etc/fargate"
            name       = "fargate-conf"
          }

          volume_mount {
            mount_path = "/etc/kubernetes"
            name       = "etc-kubernetes"
          }

          volume_mount {
            mount_path = "/usr/bin/aws-iam-authenticator"
            name       = "aws-iam-authenticator"
          }
        }

        volume {
          name = "kubeconfig"

          host_path {
            path = "/var/lib/kubelet/kubeconfig"
          }
        }

        volume {
          name = "etc-kubernetes"

          host_path {
            path = "/etc/kubernetes"
          }
        }

        volume {
          name = "aws-iam-authenticator"

          host_path {
            path = "/usr/bin/aws-iam-authenticator"
          }
        }

        volume {
          name = "fargate-conf"

          config_map {
            name = "${kubernetes_config_map.virtual-kubelet.metadata.0.name}"
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "virtual_kubelet_default_deny" {
  count     = "${var.virtual_kubelet["enabled"] * var.virtual_kubelet["default_network_policy"]}"
  metadata {
    name      = "${var.virtual_kubelet["namespace"]}-default-deny"
    namespace = "${var.virtual_kubelet["namespace"]}"
  }

  spec {
    pod_selector {}
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "virtual_kubelet_allow_namespace" {
  count     = "${var.virtual_kubelet["enabled"] * var.virtual_kubelet["default_network_policy"]}"
  metadata {
    name      = "${var.virtual_kubelet["namespace"]}-allow-namespace"
    namespace = "${var.virtual_kubelet["namespace"]}"
  }

  spec {
    pod_selector {}

    ingress = [
      {
        from = [
          {
            namespace_selector {
              match_labels = {
                name = "${var.virtual_kubelet["namespace"]}"
              }
            }
          }
        ]
      }
    ]

    policy_types = ["Ingress"]
  }
}
