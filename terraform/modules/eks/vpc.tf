#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks" {
  count      = var.vpc["create"] ? 1 : 0
  cidr_block = var.vpc["cidr"]

  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = true

  tags = merge({ "Name" = "terraform-eks-${var.cluster-name}", "kubernetes.io/cluster/${var.cluster-name}" = "shared" }, local.common_tags, var.custom_tags)
}

resource "aws_subnet" "eks" {
  count             = var.vpc["create"] ? 3 : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block = cidrsubnet(
    var.vpc["cidr"],
    3,
    length(aws_subnet.eks-private) + count.index,
  )
  vpc_id                  = aws_vpc.eks[0].id
  map_public_ip_on_launch = true

  tags = merge({ "Name" = "terraform-eks-node-${var.cluster-name}-public", "Public" = "yes", "kubernetes.io/cluster/${var.cluster-name}" = "shared", "kubernetes.io/role/elb" = "1" }, local.common_tags, var.custom_tags)
}

resource "aws_subnet" "eks-private" {
  count             = var.vpc["create"] ? 3 : 0
  availability_zone = data.aws_availability_zones.available.names[count.index]
  cidr_block        = cidrsubnet(var.vpc["cidr"], 3, count.index)
  vpc_id            = aws_vpc.eks[0].id

  tags = merge({ "Name" = "terraform-eks-node-${var.cluster-name}-private", "Public" = "no", "kubernetes.io/cluster/${var.cluster-name}" = "shared", "kubernetes.io/role/internal-elb" = "1" }, local.common_tags, var.custom_tags)
}

resource "aws_internet_gateway" "eks" {
  count  = var.vpc["create"] ? 1 : 0
  vpc_id = aws_vpc.eks[0].id

  tags = merge({ Name = "terraform-eks-${var.cluster-name}" }, local.common_tags, var.custom_tags)
}

resource "aws_route_table" "eks" {
  count  = var.vpc["create"] ? 1 : 0
  vpc_id = aws_vpc.eks[0].id
  tags   = merge({ Name = "terraform-eks-${var.cluster-name}-public" }, local.common_tags, var.custom_tags)
}

resource "aws_route_table" "eks-private" {
  count  = var.vpc["create"] ? 3 : 0
  vpc_id = aws_vpc.eks[0].id
  tags   = merge({ Name = "terraform-eks-${var.cluster-name}-private" }, local.common_tags, var.custom_tags)
}

resource "aws_route" "eks" {
  count                  = var.vpc["create"] ? 1 : 0
  route_table_id         = aws_route_table.eks[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.eks[0].id
}

resource "aws_route" "eks-private" {
  count                  = var.vpc["create"] ? 3 : 0
  route_table_id         = aws_route_table.eks-private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.eks[count.index].id
}

resource "aws_route_table_association" "eks" {
  count          = var.vpc["create"] ? 3 : 0
  subnet_id      = aws_subnet.eks[count.index].id
  route_table_id = aws_route_table.eks[0].id
}

resource "aws_route_table_association" "eks-private" {
  count          = var.vpc["create"] ? 3 : 0
  subnet_id      = aws_subnet.eks-private[count.index].id
  route_table_id = aws_route_table.eks-private[count.index].id
}

resource "aws_eip" "eks" {
  count = var.vpc["create"] ? 3 : 0
  vpc   = true
}

resource "aws_nat_gateway" "eks" {
  count         = var.vpc["create"] ? 3 : 0
  allocation_id = aws_eip.eks[count.index].id
  subnet_id     = aws_subnet.eks[count.index].id
}

output "vpc-public-subnets" {
  value = aws_subnet.eks.*.id
}

output "vpc-private-subnets" {
  value = aws_subnet.eks-private.*.id
}

output "vpc-id" {
  value = aws_vpc.eks.*.id
}
