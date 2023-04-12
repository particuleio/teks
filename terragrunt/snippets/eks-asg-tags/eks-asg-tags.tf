locals {
  mngs         = var.eks_managed_node_groups
  mng_defaults = var.eks_managed_node_group_defaults

  cluster_name = var.cluster_name

  taint_effects = {
    NO_SCHEDULE        = "NoSchedule"
    NO_EXECUTE         = "NoExecute"
    PREFER_NO_SCHEDULE = "PreferNoSchedule"
  }

  mng_ca_tags_defaults = {
    "k8s.io/cluster-autoscaler/enabled"               = "true"
    "k8s.io/cluster-autoscaler/${local.cluster_name}" = "owned"
  }

  mng_ca_tags_taints_defaults = length(try(local.mng_defaults.taints, [])) != 0 ? {
    for taint in local.mng_defaults.taints : "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}" => "${taint.value}:${local.taint_effects[taint.effect]}"
  } : {}

  mng_ca_tags_labels_defaults = try(local.mng_defaults.labels, {}) != {} ? {
    for label_key, label_value in local.mng_defaults.labels : "k8s.io/cluster-autoscaler/node-template/label/${label_key}" => label_value
  } : {}

  mng_ca_tags_resources_defaults = try(local.mng_defaults.resources, {}) != {} ? {
    for resource_key, resource_value in local.mng_defaults.resources : "k8s.io/cluster-autoscaler/node-template/resources/${resource_key}" => resource_value
  } : {}

  mng_ca_tags_taints = { for mng_key, mng_value in local.mngs : mng_key => merge(
    { for taint in mng_value.taints : "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}" => "${taint.value}:${local.taint_effects[taint.effect]}" }
    ) if length(try(mng_value.taints, [])) != 0
  }

  mng_ca_tags_labels = { for mng_key, mng_value in local.mngs : mng_key => merge(
    { for label_key, label_value in mng_value.labels : "k8s.io/cluster-autoscaler/node-template/label/${label_key}" => label_value },
    ) if try(mng_value.labels, {}) != {}
  }

  mng_ca_tags_restricted_labels = { for mng_key, mng_value in local.mngs : mng_key => merge(
    { for label_key, label_value in mng_value.restricted_labels : "k8s.io/cluster-autoscaler/node-template/label/${label_key}" => label_value },
    ) if try(mng_value.restricted_labels, {}) != {}
  }

  mng_ca_tags_implicit = { for mng_key, mng_value in local.mngs : mng_key => merge(
    length(try(mng_value.instance_types, local.mng_defaults.instance_types)) == 1 ? { "k8s.io/cluster-autoscaler/node-template/label/node.kubernetes.io/instance-type" = one(try(mng_value.instance_types, local.mng_defaults.instance_types)) } : {},
    length(try(mng_value.subnet_ids, local.mng_defaults.subnet_ids)) == 1 ? { "k8s.io/cluster-autoscaler/node-template/label/topology.ebs.csi.aws.com/zone" = one(data.aws_autoscaling_group.node_groups[mng_key].availability_zones) } : {},
    length(try(mng_value.subnet_ids, local.mng_defaults.subnet_ids)) == 1 ? { "k8s.io/cluster-autoscaler/node-template/label/topology.kubernetes.io/zone" = one(data.aws_autoscaling_group.node_groups[mng_key].availability_zones) } : {},
    )
  }

  mng_ca_tags_resources = { for mng_key, mng_value in local.mngs : mng_key => merge(
    { for resource_key, resource_value in mng_value.resource : "k8s.io/cluster-autoscaler/node-template/resources/${resource_key}" => resource_value },
    ) if try(mng_value.resources, {}) != {}
  }

  mng_ca_tags = { for mng_key, mng_value in local.mngs : mng_key => merge(
    local.mng_ca_tags_defaults,
    local.mng_ca_tags_taints_defaults,
    local.mng_ca_tags_labels_defaults,
    local.mng_ca_tags_resources_defaults,
    try(local.mng_ca_tags_taints[mng_key], {}),
    try(local.mng_ca_tags_labels[mng_key], {}),
    try(local.mng_ca_tags_restricted_labels[mng_key], {}),
    local.mng_ca_tags_implicit[mng_key],
    try(local.mng_ca_tags_resources[mng_key], {}),
  ) }

  mng_asg_custom_tags = { for mng_key, mng_value in local.mngs : mng_key => merge(var.tags, try(local.mng_defaults.tags, {}), try(mng_value.tags, {})) }
}

data "aws_autoscaling_group" "node_groups" {
  for_each = module.eks_managed_node_group
  name     = each.value.node_group_resources[0].autoscaling_groups[0].name
}

resource "aws_autoscaling_group_tag" "mng_ca" {
  # Create a tuple in a map for each ASG tag combo
  for_each = merge([for mng_key, mng_tags in local.mng_ca_tags : { for tag_key, tag_value in mng_tags : "${mng_key}-${substr(tag_key, 25, -1)}" => { mng = mng_key, key = tag_key, value = tag_value } }]...)

  # Lookup the ASG name for the MNG, erroring if there is more than one
  autoscaling_group_name = one(module.eks_managed_node_group[each.value.mng].node_group_autoscaling_group_names)

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = false
  }
}

resource "aws_autoscaling_group_tag" "mng_asg_tags" {
  # Create a tuple in a map for each ASG tag combo
  for_each = merge([for mng_key, mng_tags in local.mng_asg_custom_tags : { for tag_key, tag_value in mng_tags : "${mng_key}-${tag_key}" => { mng = mng_key, key = tag_key, value = tag_value } }]...)

  # Lookup the ASG name for the MNG, erroring if there is more than one
  autoscaling_group_name = one(module.eks_managed_node_group[each.value.mng].node_group_autoscaling_group_names)

  tag {
    key                 = each.value.key
    value               = each.value.value
    propagate_at_launch = true
  }
}
