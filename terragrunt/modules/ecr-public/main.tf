resource "aws_ecrpublic_repository" "this" {
  for_each = var.public_repositories

  repository_name = each.key

  catalog_data {
    about_text        = lookup(each.value, "about_text", "")
    architectures     = lookup(each.value, "architectures", [])
    description       = lookup(each.value, "description", "")
    logo_image_blob   = lookup(each.value, "logo_image_path", "")
    operating_systems = lookup(each.value, "operating_systems", [])
    usage_text        = lookup(each.value, "usage_text", "")
  }
}
