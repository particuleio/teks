data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

output "aws_region" {
  value = data.aws_region.current
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}
