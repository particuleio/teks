output "aws_region" {
  value       = data.aws_region.current
  description = "AWS Region"
}

output "aws_availability_zones" {
  value       = data.aws_availability_zones.available
  description = "AWS Availability Zones"
}

output "aws_account_id" {
  value       = data.aws_caller_identity.current.account_id
  description = "AWS Account ID"
}

output "aws_partition" {
  value       = data.aws_partition.current.partition
  description = "AWS Partition"
}
