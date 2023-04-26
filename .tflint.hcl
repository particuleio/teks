plugin "terraform" {
  enabled = true
  version = "0.2.2"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}
rule "terraform_naming_convention" {
  enabled = false
}

rule "terraform_unused_declarations" {
  enabled = false
}

rule "terraform_standard_module_structure" {
  enabled = false
}

rule "terraform_documented_outputs" {
  enabled = false
}

rule "terraform_unused_required_providers" {
  enabled = false
}
