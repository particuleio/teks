locals {
  aws_region = yamldecode(file("../../../region_values.yaml"))["aws_region"]
  env        = yamldecode(file("../../../../env_tags.yaml"))["Env"]
  prefix     = yamldecode(file("../../../../../global_values.yaml"))["prefix"]
  custom_tags = merge(
    yamldecode(file("../../../../../global_tags.yaml")),
    yamldecode(file("../../../../env_tags.yaml"))
  )

}
