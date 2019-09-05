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
  cluster-name = "sample"
  env          = "sample"
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

  kubernetes_version = "1.13"

  endpoint_private_access = true

  endpoint_public_access = true

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  cluster_log_retention_in_days = 180

  allowed_cidr_blocks = ["0.0.0.0/0"]

  ssh_remote_security_group_id = ""

  kubeconfig_assume_role_arn = ""

  map_users = <<MAP_USERS
  - userarn: arn:aws:iam::000000000000:user/MyUser
    username: admin
    groups:
      - system:masters
  MAP_USERS

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
    key_name = "keypair"
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
