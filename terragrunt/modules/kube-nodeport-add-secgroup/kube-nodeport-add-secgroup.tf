resource "aws_security_group_rule" "workers_ingress_cluster_node_port_tcp" {
  count             = var.worker_create_security_group && var.create_eks ? 1 : 0
  description       = "Allow Nodeport from everywhere"
  protocol          = "tcp"
  security_group_id = local.worker_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 30000
  to_port           = 32767
  type              = "ingress"
}

resource "aws_security_group_rule" "workers_ingress_cluster_node_port_udp" {
  count             = var.worker_create_security_group && var.create_eks ? 1 : 0
  description       = "Allow Nodeport from everywhere"
  protocol          = "udp"
  security_group_id = local.worker_security_group_id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 30000
  to_port           = 32767
  type              = "ingress"
}
