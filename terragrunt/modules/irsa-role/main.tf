resource "aws_iam_policy" "this" {
  for_each = var.irsa_roles
  name     = each.key
  policy   = each.value.policy
}

module "this" {
  for_each                      = var.irsa_roles
  create_role                   = true
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "~> 4.0"
  role_name                     = each.key
  provider_url                  = replace(lookup(each.value, "cluster_oidc_issuer_url", ""), "https://", "")
  role_policy_arns              = [aws_iam_policy.this[each.key].arn]
  oidc_fully_qualified_subjects = lookup(each.value, "oidc_fully_qualified_subjects", [])
  oidc_subjects_with_wildcards  = lookup(each.value, "oidc_subjects_with_wildcards", [])
  number_of_role_policy_arns    = lookup(each.value, "number_of_role_policy_arns", null)
}
