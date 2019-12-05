include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "github.com/clusterfrak-dynamics/terraform-kubernetes-addons.git?ref=v4.0.1"
}

locals {
  env        = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_tags.yaml")}"))["Env"]
  aws_region = yamldecode(file("${get_terragrunt_dir()}/${find_in_parent_folders("common_values.yaml")}"))["aws_region"]
}

dependency "eks" {
  config_path = "../eks"

  mock_outputs = {
    cluster_id = "cluster-name"
  }
}

inputs = {

  cluster-name = dependency.eks.outputs.cluster_id

  aws = {
    "region" = local.aws_region
  }

  eks = {
    "cluster_name" = dependency.eks.outputs.cluster_id
  }

  nginx_ingress = {
    version                = "0.26.1"
    chart_version          = "1.24.5"
    enabled                = true
    default_network_policy = true
    ingress_cidr           = "0.0.0.0/0"
    namespace              = "ingress-nginx"
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES

    use_nlb = false
    use_l7 = false
  }

  cluster_autoscaler = {
    create_iam_resources_kiam = true

    iam_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeAutoScalingInstances",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

    version                = "v1.14.6"
    chart_version          = "6.1.0"
    enabled                = true
    default_network_policy = true
    namespace              = "cluster-autoscaler"
    cluster_name           = dependency.eks.outputs.cluster_id
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
extraArgs:
  balance-similar-node-groups: true
EXTRA_VALUES
  }

  external_dns = {
    create_iam_resources_kiam = false

    iam_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": [
        "arn:aws:route53:::hostedzone/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets"
      ],
      "Resource": [
        "*"
      ]
    }
  ]
}
POLICY

    version                = "0.5.17-debian-9-r25"
    chart_version          = "2.10.1"
    enabled                = false
    default_network_policy = false
    namespace              = "external-dns"
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  cert_manager = {
    create_iam_resources_kiam = false

    iam_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/*"
    },
    {
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    }
  ]
}
POLICY

    version                        = "v0.9.1"
    chart_version                  = "v0.9.1"
    enabled                        = false
    default_network_policy         = false
    namespace                      = "cert-manager"
    timeout                        = 3600
    force_update                   = false
    recreate_pods                  = false
    wait                           = true
    acme_email                     = "example@email.com"
    enable_default_cluster_issuers = false

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  kiam = {
    version = "v3.4"
    chart_version = "4.2.0"
    enabled = true
    default_network_policy = true
    namespace = "kiam"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true
    server_use_host_network = "true"
    create_iam_user = true
    create_iam_resources = true
    iam_user = ""

    assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ],
      "Resource": "*"
    }
  ]
}
POLICY

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  metrics_server = {
    version = "v0.3.6"
    chart_version = "2.8.8"
    enabled = true
    default_network_policy = true
    namespace = "metrics-server"
    control_plane_private_cidr = "10.0.0.0/22"
    control_plane_public_cidr = "10.0.101.0/22"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  flux = {
    create_iam_resources_kiam = true
    version                   = "1.16.0"
    chart_version             = "0.15.0"
    enabled                   = false
    default_network_policy    = false
    namespace                 = "flux"
    allowed_namespaces        = ""
    timeout                   = 3600
    force_update              = false
    recreate_pods             = false
    wait                      = true

    extra_values = <<EXTRA_VALUES
git:
  url: "ssh://git@gitlab.com/myrepo/gitops-${local.env}.git"
  pollInterval: "1m"
helmOperator:
  create: false
  tillerNamespace: "flux"
  allowNamespace: "flux"
rbac:
  create: false
syncGarbageCollection:
  enabled: true
  dry: false
prometheus:
  enabled: false
registry:
  pollInterval: "1m"
EXTRA_VALUES
  }

  virtual_kubelet = {
    create_iam_resources_kiam = false
    create_cloudwatch_log_group = false
    cloudwatch_log_group = "eks-virtual-kubelet"
    version = "0.7.4"
    enabled = false
    default_network_policy = false
    namespace = "virtual-kubelet"
    cpu = "20"
    memory = "40Gi"
    pods = "20"
    operatingsystem = "Linux"
    platformversion = "LATEST"
    assignpublicipv4address = false
    fargate_cluster_name = "sample"
  }

  prometheus_operator = {
    chart_version = "8.3.0"
    enabled = true
    default_network_policy = true
    namespace = "monitoring"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true

    extra_values = <<EXTRA_VALUES
grafana:
  deploymentStrategy:
    type: Recreate
  ingress:
    enabled: false
    annotations:
      kubernetes.io/ingress.class: nginx
    hosts:
      - grafana.${local.env}.cfd.io
  persistence:
    enabled: true
    storageClassName: gp2
    accessModes:
      - ReadWriteOnce
    size: 10Gi
prometheus:
    replicas: 1
    retention: 180d
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: gp2
          accessModes: ["ReadWriteOnce"]
          resources:
            requests:
              storage: 50Gi
EXTRA_VALUES
  }

  fluentd_cloudwatch = {
    create_iam_resources_kiam = true
    iam_policy                = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs:DescribeLogGroups",
                "logs:DescribeLogStreams",
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
    chart_version = "0.11.1"
    version = "v1.7.4-debian-cloudwatch-1.0"
    enabled = true
    default_network_policy = true
    namespace = "fluentd-cloudwatch"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true
    containers_log_retention_in_days = 180

    extra_values = <<VALUES
VALUES
  }

  npd = {
    chart_version          = "1.6.1"
    version                = "v0.8.0"
    enabled                = true
    default_network_policy = true
    namespace              = "node-problem-detector"
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  sealed_secrets = {
    chart_version = "1.6.0"
    version = "v0.9.5"
    enabled = false
    default_network_policy = false
    namespace = "sealed-secrets"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  istio = {
    chart_version_init     = "1.2.2"
    chart_version          = "1.2.2"
    enabled_init           = false
    enabled                = false
    default_network_policy = false
    namespace              = "istio-system"
    timeout_init           = 3600
    force_update_init      = false
    recreate_pods_init     = false
    wait_init              = true
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values_init = <<EXTRA_VALUES
EXTRA_VALUES
    extra_values = <<EXTRA_VALUES
gateways:
  istio-ingressgateway:
    sds:
      enabled: true
    serviceAnnotations:
      service.beta.kubernetes.io/aws-load-balancer-type: nlb
global:
  k8sIngress:
    enabled: true
    enabledHttps: true
    gatewayName: ingressgateway
EXTRA_VALUES
  }

  cni_metrics_helper = {
    create_iam_resources_kiam = false
    enabled                   = false
    version                   = "v1.5.0"
    iam_policy                = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "cloudwatch:PutMetricData",
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Resource": "*",
      "Action": "ec2:DescribeTags"
    }
  ]
}
POLICY
  }

  kong = {
    version = "1.3"
    chart_version = "0.17.0"
    enabled = false
    default_network_policy = true
    ingress_cidr = "0.0.0.0/0"
    namespace = "kong"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  rancher = {
    chart_version          = "2.2.8"
    version                = "v2.2.8"
    enabled                = false
    channel                = "stable"
    default_network_policy = false
    namespace              = "rancher"
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  keycloak = {
    chart_version = "5.1.7"
    version = "6.0.1"
    enabled = false
    default_network_policy = false
    namespace = "keycloak"
    timeout = 3600
    force_update = false
    recreate_pods = false
    wait = false

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }

  karma = {
    chart_version          = "1.1.18"
    version                = "v0.44"
    enabled                = false
    default_network_policy = false
    namespace              = "monitoring"
    create_ns              = false
    timeout                = 3600
    force_update           = false
    recreate_pods          = false
    wait                   = true

    extra_values = <<EXTRA_VALUES
EXTRA_VALUES
  }
}

