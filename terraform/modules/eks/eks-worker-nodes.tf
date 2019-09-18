data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.kubernetes_version}*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

data "aws_ami" "eks-gpu-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-gpu-node-${var.kubernetes_version}*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

data "template_file" "eks-node" {
  count    = length(var.node-pools)
  template = file("templates/eks-node.tpl")

  vars = {
    apiserver_endpoint = aws_eks_cluster.eks.endpoint
    b64_cluster_ca     = aws_eks_cluster.eks.certificate_authority[0].data
    cluster_name       = var.cluster-name
    kubelet_extra_args = var.node-pools[count.index]["kubelet_extra_args"]
    extra_user_data    = var.node-pools[count.index]["extra_user_data"]
  }
}

resource "aws_launch_template" "eks" {
  count = length(var.node-pools)

  iam_instance_profile {
    name = aws_iam_instance_profile.eks-node[count.index].name
  }

  image_id = lookup(
    var.node-pools[count.index],
    "image_id",
    lookup(var.node-pools[count.index], "gpu_ami", "false") ? data.aws_ami.eks-gpu-worker.id : data.aws_ami.eks-worker.id,
  )
  instance_type          = var.node-pools[count.index]["instance_type"]
  name_prefix            = "terraform-eks-${var.cluster-name}-node-pool-${var.node-pools[count.index]["name"]}-"
  vpc_security_group_ids = [aws_security_group.eks-node.id]
  user_data              = base64encode(data.template_file.eks-node[count.index].rendered)
  tags                   = merge(local.common_tags, var.custom_tags)

  key_name = var.node-pools[count.index]["key_name"]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.node-pools[count.index]["volume_size"]
      volume_type = var.node-pools[count.index]["volume_type"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "eks" {
  count = length(var.node-pools)

  desired_capacity = var.node-pools[count.index]["desired_capacity"]

  launch_template {
    id      = aws_launch_template.eks[count.index].id
    version = "$Latest"
  }

  max_size    = var.node-pools[count.index]["max_size"]
  min_size    = var.node-pools[count.index]["min_size"]
  name_prefix = "terraform-eks-${var.cluster-name}-node-pool-${var.node-pools[count.index]["name"]}-"
  vpc_zone_identifier = var.node-pools[count.index]["vpc_zone_identifier"] != [] ? var.node-pools[count.index]["vpc_zone_identifier"] : split(
    ",",
    var.vpc["create"] ? join(",", aws_subnet.eks-private.*.id) : var.vpc["private_subnets_id"],
  )

  tags = concat(
    [
      {
        "key"                 = "Name"
        "value"               = "terraform-eks-${var.cluster-name}-${var.node-pools[count.index]["name"]}"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "kubernetes.io/cluster/${var.cluster-name}"
        "value"               = "owned"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "k8s.io/cluster-autoscaler/${var.node-pools[count.index]["autoscaling"]}"
        "value"               = "1"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
        "value"               = "1"
        "propagate_at_launch" = true
      },
      {
        "key"                 = "eks:node-pool:name"
        "value"               = var.node-pools[count.index]["name"]
        "propagate_at_launch" = true
      },
    ],
    var.node-pools[count.index]["tags"],
    [
      for k, v in var.custom_tags : { "key" = k, "value" = v, "propagate_at_launch" = true }
    ],
    [
      for k, v in local.common_tags : { "key" = k, "value" = v, "propagate_at_launch" = true }
    ]
  )

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}
