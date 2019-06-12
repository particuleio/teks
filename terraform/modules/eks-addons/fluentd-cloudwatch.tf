locals {
  values_fluentd_cloudwatch = <<VALUES
image:
  tag: ${var.fluentd_cloudwatch["version"]}
rbac:
  create: true
nodeSelector:
  node-role.kubernetes.io/node: ""
tolerations:
  - operator: Exists
awsRegion: "${var.aws["region"]}"
logGroupName: "${var.fluentd_cloudwatch["log_group_name"]}"
extraVars:
  - "{ name: FLUENT_UID, value: '0' }"
updateStrategy:
  type: RollingUpdate
VALUES
  values_fluentd_cloudwatch_kiam = <<VALUES
image:
  tag: ${var.fluentd_cloudwatch["version"]}
rbac:
  create: true
nodeSelector:
  node-role.kubernetes.io/node: ""
tolerations:
  - operator: Exists
awsRole: "${join(",", data.terraform_remote_state.eks.*.fluentd-cloudwatch-kiam-role-arn[0])}"
awsRegion: "${var.aws["region"]}"
logGroupName: "${var.fluentd_cloudwatch["log_group_name"]}"
extraVars:
  - "{ name: FLUENT_UID, value: '0' }"
updateStrategy: 
  type: RollingUpdate
VALUES
}

resource "kubernetes_namespace" "fluentd_cloudwatch" {
  count = "${var.fluentd_cloudwatch["enabled"] ? 1 : 0 }"
  metadata {
    annotations {
      "iam.amazonaws.com/permitted" = ".*"
    }

    labels {
      name = "${var.fluentd_cloudwatch["namespace"]}"
    }

    name = "${var.fluentd_cloudwatch["namespace"]}"
  }
}

resource "helm_release" "fluentd_cloudwatch" {
  depends_on = [
    "kubernetes_namespace.fluentd_cloudwatch"
  ]
  count     = "${var.fluentd_cloudwatch["enabled"] ? 1 : 0 }"
  repository = "${data.helm_repository.incubator.metadata.0.name}"
  name      = "fluentd-cloudwatch"
  chart     = "fluentd-cloudwatch"
  version   = "${var.fluentd_cloudwatch["chart_version"]}"
  values    = ["${concat(list(var.fluentd_cloudwatch["use_kiam"] ? local.values_fluentd_cloudwatch_kiam : local.values_fluentd_cloudwatch),list(var.fluentd_cloudwatch["extra_values"]))}"]
  namespace = "${var.fluentd_cloudwatch["namespace"]}"
}
