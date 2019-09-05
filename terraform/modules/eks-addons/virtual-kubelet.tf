resource "aws_iam_role" "eks-virtual-kubelet-ecs-task" {
  name  = "tf-eks-${var.cluster-name}-virtual-kubelet-ecs-task"
  count = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet-ecs-task" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.eks-virtual-kubelet-ecs-task[count.index].name
  count      = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0
}

resource "aws_iam_role" "eks-virtual-kubelet" {
  name  = "tf-eks-${var.cluster-name}-virtual-kubelet"
  count = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": "${aws_iam_role.eks-kiam-server-role[count.index].arn}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_iam_role_policy_attachment" "eks-virtual-kubelet" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
  role       = aws_iam_role.eks-virtual-kubelet[count.index].name
  count      = var.virtual_kubelet["create_iam_resources_kiam"] ? 1 : 0
}

resource "aws_cloudwatch_log_group" "eks-virtual-kubelet" {
  name  = "eks-cluster-${var.cluster-name}-${var.virtual_kubelet["cloudwatch_log_group"]}"
  count = var.virtual_kubelet["create_cloudwatch_log_group"] ? 1 : 0

  tags = {
    Environment = "tf-eks-${var.cluster-name}"
    Application = "virtual-kubelet"
  }
}

resource "kubernetes_namespace" "virtual-kubelet" {
  count = var.virtual_kubelet["enabled"] ? 1 : 0

  depends_on = [helm_release.kiam]

  metadata {
    annotations = {
      "iam.amazonaws.com/permitted" = "${aws_iam_role.eks-virtual-kubelet[count.index].arn}"
    }

    labels = {
      name = var.virtual_kubelet["namespace"]
    }

    name = var.virtual_kubelet["namespace"]
  }
}

resource "kubernetes_config_map" "virtual-kubelet" {
  count = var.virtual_kubelet["enabled"] ? 1 : 0

  depends_on = [helm_release.kiam]

  metadata {
    name      = "virtual-kubelet-fargate-conf"
    namespace = kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]
  }

  data = {
    "fargate.toml" = <<DATA
Region = "${var.aws["region"]}"
ClusterName = "${var.virtual_kubelet["fargate_cluster_name"]}"
Subnets = ["${join(
    "\",\"",
    data.terraform_remote_state.eks.outputs.vpc-private-subnets,
)}"]
SecurityGroups = ["${data.terraform_remote_state.eks.outputs.eks-node-sg}"]
AssignPublicIPv4Address = false
ExecutionRoleArn = "${aws_iam_role.eks-virtual-kubelet-ecs-task[0].arn}"
CloudWatchLogGroupName = "${aws_cloudwatch_log_group.eks-virtual-kubelet[0].name}"
PlatformVersion = "${var.virtual_kubelet["platformversion"]}"
OperatingSystem = "${var.virtual_kubelet["operatingsystem"]}"
CPU = "${var.virtual_kubelet["cpu"]}"
Memory = "${var.virtual_kubelet["memory"]}"
Pods = "${var.virtual_kubelet["pods"]}"
DATA

}
}

resource "kubernetes_deployment" "virtual-kubelet" {
  count = var.virtual_kubelet["enabled"] ? 1 : 0

  metadata {
    name      = "virtual-kubelet"
    namespace = kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]

    labels = {
      app = "virtual-kubelet"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "virtual-kubelet"
      }
    }

    template {
      metadata {
        labels = {
          app = "virtual-kubelet"
        }

        annotations = {
          "iam.amazonaws.com/role" = aws_iam_role.eks-virtual-kubelet[count.index].arn
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
            name = kubernetes_config_map.virtual-kubelet[0].metadata[0].name
          }
        }
      }
    }
  }
}

resource "kubernetes_network_policy" "virtual_kubelet_default_deny" {
  count = (var.virtual_kubelet["enabled"] ? 1 : 0) * (var.virtual_kubelet["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]}-default-deny"
    namespace = kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }
    policy_types = ["Ingress"]
  }
}

resource "kubernetes_network_policy" "virtual_kubelet_allow_namespace" {
  count = (var.virtual_kubelet["enabled"] ? 1 : 0) * (var.virtual_kubelet["default_network_policy"] ? 1 : 0)

  metadata {
    name      = "${kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]}-allow-namespace"
    namespace = kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]
  }

  spec {
    pod_selector {
    }

    ingress {
      from {
        namespace_selector {
          match_labels = {
            name = kubernetes_namespace.virtual-kubelet.*.metadata.0.name[count.index]
          }
        }
      }
    }

    policy_types = ["Ingress"]
  }
}

