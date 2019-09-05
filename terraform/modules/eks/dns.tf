data "aws_route53_zone" "parent" {
  name  = var.dns["domain_name"]
  count = var.dns["use_route53"] && var.dns["create_ns_in_parent"] ? 1 : 0
}

resource "aws_route53_zone" "eks" {
  name  = "${var.dns["subdomain_name"]}.${var.dns["domain_name"]}"
  count = var.dns["use_route53"] ? 1 : 0

  dynamic "vpc" {
    for_each = ! var.dns["private"] ? [] : list("vpc")

    content {
      vpc_id = var.vpc["create"] ? join(",", aws_vpc.eks.*.id) : var.vpc["vpc_id"]
    }
  }
}

resource "aws_route53_record" "ns_in_parent" {
  zone_id = data.aws_route53_zone.parent[0].zone_id
  name    = var.dns["subdomain_name"]
  type    = "NS"
  ttl     = var.dns["subdomain_default_ttl"]
  records = aws_route53_zone.eks[0].name_servers
  count   = var.dns["use_route53"] && var.dns["create_ns_in_parent"] ? 1 : 0
}

output "aws_route53_zone_id" {
  value = aws_route53_zone.eks[*].zone_id
}
