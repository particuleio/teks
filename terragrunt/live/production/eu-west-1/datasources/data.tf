data "aws_region" "current" {}

data "aws_availability_zones" "available" {}

data "aws_partition" "current" {}

data "aws_caller_identity" "current" {}

output "aws_region" {
  value = data.aws_region.current
}

output "aws_availability_zones" {
  value = data.aws_availability_zones.available
}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "aws_partition" {
  value = data.aws_partition.current.partition
}
