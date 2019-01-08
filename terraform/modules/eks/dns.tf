data "aws_route53_zone" "parent" {
  name  = "${var.domain_name}"
  count = "${var.use_route53}"
}

resource "aws_route53_zone" "eks" {
  name  = "${var.subdomain_name}.${var.domain_name}"
  count = "${var.use_route53}"
}

resource "aws_route53_record" "ns_in_parent" {
  zone_id = "${data.aws_route53_zone.parent.zone_id}"
  name    = "${var.subdomain_name}"
  type    = "NS"
  ttl     = "${var.subdomain_default_ttl}"
  records = ["${aws_route53_zone.eks.name_servers}"]
  count   = "${var.use_route53}"
}
