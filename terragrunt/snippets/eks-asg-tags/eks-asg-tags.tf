data "aws_autoscaling_group" "node_groups" {
  for_each = module.eks_managed_node_group
  name     = each.value.node_group_resources.0.autoscaling_groups.0.name
}

data "aws_arn" "node_groups" {
  for_each = data.aws_autoscaling_group.node_groups
  arn      = each.value.arn
}

resource "null_resource" "node_groups_asg_tags" {
  for_each = data.aws_autoscaling_group.node_groups

  triggers = {
    asg               = each.value.arn
    labels            = jsonencode(lookup(var.eks_managed_node_groups[each.key], "labels", null))
    taints            = jsonencode(lookup(var.eks_managed_node_groups[each.key], "taint", null))
    restricted_labels = jsonencode(lookup(var.eks_managed_node_groups[each.key], "restricted_labels", null))
    instance_types    = jsonencode(lookup(var.eks_managed_node_groups[each.key], "instance_types", null))
    filemd5           = filemd5("eks-asg-tags.tf")
  }

  provisioner "local-exec" {
    command = <<EOF

    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${lookup(var.eks_managed_node_groups[each.key], "labels", null) == null ? "[]" : jsonencode([for k, v in var.eks_managed_node_groups[each.key].labels : {
    "ResourceId" : each.value.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/label/${k}",
    "Value" : v,
    "PropagateAtLaunch" : true
    }])}'
    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${lookup(var.eks_managed_node_groups[each.key], "restricted_labels", null) == null ? "[]" : jsonencode([for k, v in var.eks_managed_node_groups[each.key].restricted_labels : {
    "ResourceId" : each.value.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/label/${k}",
    "Value" : v,
    "PropagateAtLaunch" : true
  }])}'
    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${jsonencode({
  "ResourceId" : each.value.name
  "ResourceType" : "auto-scaling-group",
  "Key" : "k8s.io/cluster-autoscaler/node-template/label/topology.kubernetes.io/zone",
  "Value" : one(data.aws_autoscaling_group.node_groups[each.key].availability_zones),
  "PropagateAtLaunch" : true
  })}'
    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${jsonencode({
  "ResourceId" : each.value.name
  "ResourceType" : "auto-scaling-group",
  "Key" : "k8s.io/cluster-autoscaler/node-template/label/topology.ebs.csi.aws.com/zone",
  "Value" : one(data.aws_autoscaling_group.node_groups[each.key].availability_zones),
  "PropagateAtLaunch" : true
  })}'
    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${jsonencode({
  "ResourceId" : each.value.name
  "ResourceType" : "auto-scaling-group",
  "Key" : "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type",
  "Value" : one(var.eks_managed_node_groups[each.key].instance_types),
  "PropagateAtLaunch" : true
  })}'
    aws autoscaling create-or-update-tags --region ${data.aws_arn.node_groups[each.key].region} --tags '${lookup(var.eks_managed_node_groups[each.key], "taint", null) == null ? "[]" : jsonencode([for i in var.eks_managed_node_groups[each.key].taint : {
    "ResourceId" : each.value.name
    "ResourceType" : "auto-scaling-group",
    "Key" : "k8s.io/cluster-autoscaler/node-template/taint/${i.key}",
    "Value" : "${i.value}:${replace(title(replace(lower(i.effect), "_", " ")), " ", "")}",
    "PropagateAtLaunch" : true
}])}'
    EOF
}
}
