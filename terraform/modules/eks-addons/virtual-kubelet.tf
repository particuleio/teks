resource "kubernetes_namespace" "virtual-kubelet" {
  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    name = "${var.virtual_kubelet["namespace"]}"
  }
}

resource "kubernetes_config_map" "virtual-kubelet" {
  metadata {
    name      = "fargate-toml"
    namespace = "${var.virtual_kubelet["namespace"]}"
  }

  data {
    fargate.toml = <<DATA
Region = "${var.aws["region"]}"
ClusterName = "${var.virtual_kubelet["fargate_cluster_name"]}"
Subnets = ["${join("\",\"", data.terraform_remote_state.eks.vpc-private-subnets)}"]
SecurityGroups = ["${data.terraform_remote_state.eks.eks-node-sg}"]
AssignPublicIPv4Address = "${var.virtual_kubelet["assignpublicipv4address"]}"
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
