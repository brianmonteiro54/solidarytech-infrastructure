# =============================================================================
# Providers — SolidaryTech Infrastructure (Fase 5)
# =============================================================================
# Define versões mínimas do Terraform e do provider AWS.
# Versões pinadas com ~> para permitir patches mas evitar surpresas.
# =============================================================================

terraform {
  required_version = ">= 1.14.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.46"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}
