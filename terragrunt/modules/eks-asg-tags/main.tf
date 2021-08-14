data "aws_autoscaling_group" "node_groups" {
  for_each = var.node_groups
  name     = each.value.resources.0.autoscaling_groups.0.name
}

data "aws_arn" "node_groups" {
  for_each = data.aws_autoscaling_group.node_groups
  arn      = each.value.arn
}

resource "null_resource" "node_groups_asg_tags" {
  for_each = data.aws_autoscaling_group.node_groups

  triggers = {
    "asg"    = each.value.arn
    "labels" = jsonencode(var.node_groups[each.key].labels)
    "taints" = jsonencode(var.node_groups[each.key].taint)
  }

  provisioner "local-exec" {
    command = <<EOF

    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${var.node_groups[each.key].labels == null ? "[]" : jsonencode([for k, v in var.node_groups[each.key].labels : {
    "ResourceId" : each.value.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/label/${k}",
    "Value" : v,
    "PropagateAtLaunch" : true
    }])}'
      aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${var.node_groups[each.key].taint == null ? "[]" : jsonencode([for i in var.node_groups[each.key].taint : {
    "ResourceId" : each.value.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/taint/${i.key}",
    "Value" : "${i.value}:${replace(title(replace(lower(i.effect), "_", " ")), " ", "")}",
    "PropagateAtLaunch" : true
}])}'
    EOF
}
}
