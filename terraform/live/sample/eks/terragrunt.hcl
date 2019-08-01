include {
  path = "${find_in_parent_folders()}"
}

terraform {
  source = "../../../modules//eks"

  after_hook "kubeconfig" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output kubeconfig 2>/dev/null > ${get_terragrunt_dir()}/kubeconfig"]
  }

  after_hook "configmap" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output config_map_aws_auth 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }

  after_hook "calico" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output calico_yaml 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }

  after_hook "cni_metrics_helper" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output cni_metrics_helper_yaml 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }

  after_hook "helm" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output helm_rbac 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig label --overwrite ns kube-system name=kube-system"]
  }

}

inputs = {
  //
  // [provider]
  //
  aws = {
    "region" = "eu-west-1"
  }

  //
  // [vpc]
  //
  vpc = {
    create             = true
    cidr               = "10.0.0.0/16"
    vpc_id             = "vpc-0fd2efe63408f5aba"
    public_subnets_id  = "subnet-0a60f7202528d8f64,subnet-0f7deaa3e53b86817,subnet-0f58143b87ef10257"
    private_subnets_id = "subnet-0b0cca9118459c6c9,subnet-0296207fa6ff0c9ce,subnet-00f139ff79e016c19"
  }

  //
  // [dns]
  //
  use_route53 = false

  domain_name = "example.domain"

  subdomain_name = "eks"

  //
  // [kubernetes]
  //
  cluster-name = "sample"

  kubernetes_version = "1.13"

  endpoint_private_access = true

  endpoint_public_access = true

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_log_retention_in_days = 180

  allowed_cidr_blocks = ["0.0.0.0/0"]

  ssh_remote_security_group_id = ""

  map_users = <<MAP_USERS
  - userarn: arn:aws:iam::000000000000:user/MyUser
    username: admin
    groups:
      - system:masters
  MAP_USERS

  extra_network_policies = <<EXTRA_NETWORK_POLICIES
  EXTRA_NETWORK_POLICIES

  //
  // [cluster_autoscaler]
  //
  cluster_autoscaler = {
    create_iam_resources      = false
    create_iam_resources_kiam = false
    attach_to_pool            = 0

    iam_policy = <<-POLICY
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
  }

  //
  // [external_dns]
  //
  external_dns = {
    create_iam_resources      = false
    create_iam_resources_kiam = false
    attach_to_pool            = 0

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
  }

  //
  // [cert_manager]
  //
  cert_manager = {
    create_iam_resources      = false
    create_iam_resources_kiam = false
    attach_to_pool            = 0

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
  }

  //
  // [kiam]
  //
  kiam = {
    create_iam_resources = false
    attach_to_pool       = null
    create_iam_user      = false
  }

  fluentd_cloudwatch = {
    create_iam_resources      = false
    create_iam_resources_kiam = false

    iam_policy = <<POLICY
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
  }

  virtual_kubelet = {
    create_iam_resources_kiam   = false
    create_cloudwatch_log_group = false
    cloudwatch_log_group        = "eks-virtual-kubelet"
  }

  cni_metrics_helper = {
    create_iam_resources      = false
    create_iam_resources_kiam = false
    use_kiam                  = false
    attach_to_pool            = 0

    iam_policy = <<POLICY
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
      "Resource": "*"
      "Action": "ec2:DescribeTags",
    }
  ]
}
POLICY

    deployment_scheduling = <<EXTRA_SCHEDULING
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/controller
          operator: Exists
tolerations:
  - operator: Exists
    effect: NoSchedule
    key: "node-role.kubernetes.io/controller"
EXTRA_SCHEDULING

    deployment_scheduling_kiam = <<EXTRA_SCHEDULING
EXTRA_SCHEDULING
  }

  node-pools = [
    {
      name            = "default"
      extra_user_data = <<EXTRA_USER_DATA
EXTRA_USER_DATA

      min_size           = 1
      max_size           = 1
      desired_capacity   = 1
      instance_type      = "t3.medium"
      key_name           = "ocelot"
      volume_size        = 30
      volume_type        = "gp2"
      autoscaling        = "enabled"
      kubelet_extra_args = "--kubelet-extra-args '--node-labels node-role.kubernetes.io/node=\"\" --kube-reserved cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
      tags = [
        {
          key                 = "Env"
          value               = "Sample"
          propagate_at_launch = true
        },
      ],
    },
  ]

}
