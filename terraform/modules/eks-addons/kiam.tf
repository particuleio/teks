locals {
  values_kiam = <<VALUES
psp:
  create: true
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
  whiteListRouteRegexp: "/latest/dynamic/instance-identity/document"
server:
  service:
    targetPort: 11443
  useHostNetwork: ${var.kiam["server_use_host_network"]}
  image:
    tag: ${var.kiam["version"]}
  assumeRoleArn: ${aws_iam_role.eks-kiam-server-role[0].arn}
  extraHostPathMounts:
    - name: ssl-certs
      mountPath: /etc/ssl/certs
      hostPath: /etc/pki/ca-trust/extracted/pem
      readOnly: true
  extraEnv:
    AWS_DEFAULT_REGION: ${var.aws["region"]}
    AWS_ACCESS_KEY_ID: ${aws_iam_access_key.eks-kiam-user-key[0].id}
    AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.eks-kiam-user-key[0].secret}
VALUES
}

resource "aws_iam_policy" "eks-kiam-server-node" {
  count = var.kiam["create_iam_resources"] ? 1 : 0
  name  = "tf-eks-${var.cluster-name}-kiam-server-node"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/tf-eks-${var.cluster-name}-kiam-server-role"
    }
  ]
}
EOF

}

resource "aws_iam_role" "eks-kiam-server-role" {
  count       = var.kiam["create_iam_resources"] ? 1 : 0
  name        = "tf-eks-${var.cluster-name}-kiam-server-role"
  description = "Role the Kiam Server process assumes"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "${var.kiam["create_iam_user"] ? aws_iam_user.eks-kiam-user[0].arn : var.kiam["iam_user"]}"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_policy" "eks-kiam-server-policy" {
  count       = var.kiam["create_iam_resources"] ? 1 : 0
  name        = "tf-eks-${var.cluster-name}-kiam-server-policy"
  description = "Policy for the Kiam Server process"
  policy      = var.kiam["assume_role_policy"]
}

resource "aws_iam_user" "eks-kiam-user" {
  count = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  name  = "tf-eks-${var.cluster-name}-kiam-user"
}

resource "aws_iam_access_key" "eks-kiam-user-key" {
  count = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  user  = aws_iam_user.eks-kiam-user[0].name
}

resource "aws_iam_user_policy_attachment" "eks-kiam-user" {
  count      = var.kiam["create_iam_resources"] ? var.kiam["create_iam_user"] ? 1 : 0 : 0
  user       = aws_iam_user.eks-kiam-user[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-node[0].arn
}

resource "aws_iam_role_policy_attachment" "eks-kiam-server-policy" {
  count      = var.kiam["create_iam_resources"] ? 1 : 0
  role       = aws_iam_role.eks-kiam-server-role[0].name
  policy_arn = aws_iam_policy.eks-kiam-server-policy[0].arn
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
  count         = var.kiam["enabled"] ? 1 : 0
  repository    = data.helm_repository.stable.metadata[0].name
  name          = "kiam"
  chart         = "kiam"
  version       = var.kiam["chart_version"]
  timeout       = var.kiam["timeout"]
  force_update  = var.kiam["force_update"]
  recreate_pods = var.kiam["recreate_pods"]
  wait          = var.kiam["wait"]
  values        = concat([local.values_kiam], [var.kiam["extra_values"]])
  namespace     = kubernetes_namespace.kiam.*.metadata.0.name[count.index]
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
