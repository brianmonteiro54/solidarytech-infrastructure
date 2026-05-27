# =============================================================================
# TFLint Configuration
# =============================================================================

config {
  call_module_type = "all"
  force            = false
}

# -----------------------------------------------------------------------------
# Plugins
# -----------------------------------------------------------------------------

plugin "aws" {
  enabled = true
  version = "0.45.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

plugin "terraform" {
  enabled = true
  version = "0.14.1"
  source  = "github.com/terraform-linters/tflint-ruleset-terraform"
  preset  = "recommended"
}

# -----------------------------------------------------------------------------
# AWS Rules
# -----------------------------------------------------------------------------


rule "aws_dynamodb_table_invalid_name" {
  enabled = true
}

rule "aws_kms_key_invalid_key_usage" {
  enabled = true
}

# -----------------------------------------------------------------------------
# Terraform Best Practices
# -----------------------------------------------------------------------------

rule "terraform_required_version" {
  enabled = true
}

rule "terraform_required_providers" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true

  variable { format = "snake_case" }
  locals   { format = "snake_case" }
  output   { format = "snake_case" }
  resource { format = "snake_case" }
  module   { format = "snake_case" }
  data     { format = "snake_case" }
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_module_version" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_workspace_remote" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_standard_module_structure" {
  enabled = true
}