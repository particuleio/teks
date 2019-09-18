resource "aws_iam_role" "bastion" {
  name  = "terraform-eks-${var.cluster-name}-bastion"
  count = var.bastion["create"] ? 1 : 0

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY

}

resource "aws_security_group" "bastion" {
  count       = var.bastion["create"] ? 1 : 0
  name        = "terraform-eks-${var.cluster-name}-bastion"
  description = "Security group for bastion instance"
  vpc_id      = var.vpc["create"] ? join(",", aws_vpc.eks.*.id) : var.vpc["vpc_id"]

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge({ "Name" = "terraform-eks-${var.cluster-name}-bastion" }, local.common_tags, var.custom_tags)
}

resource "aws_security_group_rule" "bastion" {
  count             = var.bastion["create"] ? 1 : 0
  description       = "Allow bastion to receive SSH communication from a remote CIDR"
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.bastion[count.index].id
  cidr_blocks       = var.bastion["cidr_blocks"]
  to_port           = 22
  type              = "ingress"
}

resource "aws_iam_instance_profile" "bastion" {
  name  = "terraform-eks-${var.cluster-name}-bastion"
  role  = aws_iam_role.bastion[count.index].name
  count = var.bastion["create"] ? 1 : 0
}

resource "aws_launch_template" "bastion" {
  count = var.bastion["create"] ? 1 : 0

  iam_instance_profile {
    name = aws_iam_instance_profile.bastion[count.index].name
  }

  image_id               = var.bastion["image_id"]
  instance_type          = var.bastion["instance_type"]
  name_prefix            = "terraform-eks-${var.cluster-name}-bastion-"
  vpc_security_group_ids = [aws_security_group.bastion[count.index].id]
  user_data              = base64encode(var.bastion["user_data"])
  tags                   = merge(local.common_tags, var.custom_tags)

  key_name = var.bastion["key_name"]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.bastion["volume_size"]
      volume_type = var.bastion["volume_type"]
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "bastion" {
  count = var.bastion["create"] ? 1 : 0

  desired_capacity = 1

  launch_template {
    id      = aws_launch_template.bastion[count.index].id
    version = "$Latest"
  }

  max_size    = 1
  min_size    = 1
  name_prefix = "terraform-eks-${var.cluster-name}-bastion-"
  vpc_zone_identifier = var.bastion["vpc_zone_identifier"] != [] ? var.bastion["vpc_zone_identifier"] : split(
    ",",
    var.vpc["create"] ? join(",", aws_subnet.eks.*.id) : var.vpc["public_subnets_id"],
  )

  tags = concat(
    [
      {
        "key"                 = "Name"
        "value"               = "terraform-eks-${var.cluster-name}-bastion"
        "propagate_at_launch" = true
      },
    ],
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

output "bastion-sg" {
  value = aws_security_group.bastion[0].id
}
