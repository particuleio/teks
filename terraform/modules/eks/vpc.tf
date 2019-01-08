#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

resource "aws_vpc" "eks" {
  cidr_block = "10.0.0.0/16"

  tags = "${
    map(
     "Name", "terraform-eks-${var.cluster-name}",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks" {
  count = 3

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "terraform-eks-node-${var.cluster-name}-public",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
    )
  }"
}

resource "aws_subnet" "eks-private" {
  count = 3

  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block        = "10.0.4${count.index}.0/24"
  vpc_id            = "${aws_vpc.eks.id}"

  tags = "${
    map(
     "Name", "terraform-eks-node-${var.cluster-name}-private",
     "kubernetes.io/cluster/${var.cluster-name}", "shared",
     "kubernetes.io/role/internal-elb", "1",
    )
  }"
}

resource "aws_internet_gateway" "eks" {
  vpc_id = "${aws_vpc.eks.id}"

  tags {
    Name = "terraform-eks-${var.cluster-name}"
  }
}

resource "aws_route_table" "eks" {
  vpc_id = "${aws_vpc.eks.id}"
}

resource "aws_route_table" "eks-private" {
  vpc_id = "${aws_vpc.eks.id}"
  count  = 3
}

resource "aws_route" "eks" {
  route_table_id         = "${aws_route_table.eks.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.eks.id}"
}

resource "aws_route" "eks-private" {
  count                  = 3
  route_table_id         = "${aws_route_table.eks-private.*.id[count.index]}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.eks.*.id[count.index]}"
}

resource "aws_route_table_association" "eks" {
  count = 3

  subnet_id      = "${aws_subnet.eks.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks.id}"
}

resource "aws_route_table_association" "eks-private" {
  count = 3

  subnet_id      = "${aws_subnet.eks-private.*.id[count.index]}"
  route_table_id = "${aws_route_table.eks-private.*.id[count.index]}"
}

resource "aws_eip" "eks" {
  count = 3
  vpc   = true
}

resource "aws_nat_gateway" "eks" {
  count         = 3
  allocation_id = "${aws_eip.eks.*.id[count.index]}"
  subnet_id     = "${aws_subnet.eks.*.id[count.index]}"
}
