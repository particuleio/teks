terragrunt = {
  include {
    path = "${find_in_parent_folders()}"
  }
  terraform {
    source = "../../../modules//eks"
    after_hook "kubeconfig" {
      commands = ["apply"]
      execute = ["bash","-c","terraform output kubeconfig 2>/dev/null > ${get_tfvars_dir()}/kubeconfig"]
    }
    after_hook "configmap" {
      commands = ["apply"]
      execute = ["bash","-c","terraform output config_map_aws_auth 2>/dev/null | kubectl --kubeconfig ${get_tfvars_dir()}/kubeconfig apply -f -"]
    }
    after_hook "helm" {
      commands = ["apply"]
      execute = ["bash","-c","terraform output helm_rbac 2>/dev/null | kubectl --kubeconfig ${get_tfvars_dir()}/kubeconfig apply -f -"]
    }
  }
}

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
  create = true
  cidr = "10.0.0.0/16"
  vpc_id = "vpc-0fd2efe63408f5aba"
  public_subnets_id = "subnet-0a60f7202528d8f64,subnet-0f7deaa3e53b86817,subnet-0f58143b87ef10257"
  private_subnets_id = "subnet-0b0cca9118459c6c9,subnet-0296207fa6ff0c9ce,subnet-00f139ff79e016c19"
}

//
// [dns]
//
use_route53 = false
domain_name = "archifleks.net"
subdomain_name = "eks"

//
// [kubernetes]
//
cluster-name = "sample"
kubernetes_version = "1.11"

//
// [cluster_autoscaler]
//
cluster_autoscaler = {
  create_iam_resources = false
  create_iam_resources_kiam = false
  attach_to_pool = 0
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
}

//
// [external_dns]
//
external_dns = {
  create_iam_resources = false
  create_iam_resources_kiam = false
  attach_to_pool = 0
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
  create_iam_resources = false
  create_iam_resources_kiam = false
  attach_to_pool = 0
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
  attach_to_pool = 0
}

virtual_kubelet = {
  create_iam_resources_kiam = false
  create_cloudwatch_log_group = false
  cloudwatch_log_group = "virtual-kubelet"
}

node-pools = [
  {
    name = "controller"
    min_size = 1
    max_size = 1
    desired_capacity = 1
    instance_type = "t3.medium"
    key_name = "klefevre-sorrow"
    volume_size = 30
    volume_type = "gp2"
    autoscaling = "disabled"
    kubelet_extra_args = "--kubelet-extra-args '--node-labels node-role.kubernetes.io/controller=\"\" --register-with-taints node-role.kubernetes.io/controller=:NoSchedule --kube-reserved cpu=250m,memory=0.5Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
  },
  {
    name = "default"
    min_size = 3
    max_size = 9
    desired_capacity = 3
    instance_type = "t3.medium"
    key_name = "klefevre-sorrow"
    volume_size = 30
    volume_type = "gp2"
    autoscaling = "enabled"
    kubelet_extra_args = "--kubelet-extra-args '--node-labels node-role.kubernetes.io/node=\"\" --kube-reserved cpu=250m,memory=0.5Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
  },
]
