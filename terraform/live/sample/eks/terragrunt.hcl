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

  after_hook "helm" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output helm_rbac 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }

  after_hook "kube-system-label" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig label --overwrite ns kube-system name=kube-system"]
  }

  after_hook "kube-system-annotation" {
    commands = ["apply"]
    execute  = ["bash", "-c", "kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig annotate --overwrite ns kube-system iam.amazonaws.com/permitted=.*"]
  }

  after_hook "network-policies" {
    commands = ["apply"]
    execute  = ["bash", "-c", "terraform output network_policies 2>/dev/null | kubectl --kubeconfig ${get_terragrunt_dir()}/kubeconfig apply -f -"]
  }
}

locals {
  aws_region   = basename(dirname(get_terragrunt_dir()))
  cluster-name = "sample"
  env          = "sample"
  key_name     = "sample"
  custom_tags  = {}
}

inputs = {

  //
  // [provider]
  //
  aws = {
    "region" = local.aws_region
  }

  //
  // [vpc]
  //
  vpc = {
    create             = true
    cidr               = "10.0.0.0/16"
    vpc_id             = ""
    public_subnets_id  = ""
    private_subnets_id = ""
  }

  //
  // [dns]
  //

  dns = {
    use_route53           = false
    domain_name           = "sample.internal"
    subdomain_name        = local.env
    subdomain_default_ttl = 300
    create_ns_in_parent   = false
    private               = true
  }

  //
  // [kubernetes]
  //
  cluster-name = local.cluster-name

  kubernetes_version = "1.14"

  endpoint_private_access = true

  endpoint_public_access = true

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_log_retention_in_days = 180

  allowed_cidr_blocks = ["0.0.0.0/0"]

  ssh_remote_security_group_id = ""

  kubeconfig_assume_role_arn = ""

  map_users = <<MAP_USERS
MAP_USERS
  map_roles = <<MAP_ROLES
MAP_ROLES

  extra_network_policies = <<EXTRA_NETWORK_POLICIES
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-coredns-cluster-dns-with-host-net
  namespace: kube-system
spec:
  ingress:
  - from:
    - ipBlock:
        cidr: 10.0.0.0/17
    ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP
  podSelector:
    matchLabels:
      k8s-app: kube-dns
  policyTypes:
  - Ingress
EXTRA_NETWORK_POLICIES

custom_tags = merge(
    {
      "Env" = local.env
    },
    local.custom_tags
)

bastion = {
  create = true
  image_id = "ami-08c1db9058a6ce304"
  instance_type = "t3.small"
  key_name = local.key_name
  volume_size = 10
  volume_type = "gp2"
  vpc_zone_identifier = []
  cidr_blocks = [
    "0.0.0.0/0"
  ]

  user_data = <<USER_DATA
USER_DATA
}

node-pools = [
  {
    name = "default"

    extra_user_data = <<EXTRA_USER_DATA
EXTRA_USER_DATA

    min_size = 1
    max_size = 2
    desired_capacity = 1
    vpc_zone_identifier = []
    gpu_ami = false
    instance_type = "t3.medium"
    key_name = local.key_name
    volume_size = 50
    volume_type = "gp2"
    autoscaling = "enabled"
    kubelet_extra_args = "--kubelet-extra-args '--node-labels=node-role.kubernetes.io/node=\"\" --kube-reserved cpu=250m,memory=0.5Gi,ephemeral-storage=1Gi --system-reserved cpu=250m,memory=0.2Gi,ephemeral-storage=1Gi --eviction-hard memory.available<500Mi,nodefs.available<10%'"
    tags = [
      {
        key = "Env"
        value = local.env
        propagate_at_launch = true
      },
      {
        key = "CLUSTER_ID"
        value = local.cluster-name
        propagate_at_launch = true
      },
    ],
  },
]

}
