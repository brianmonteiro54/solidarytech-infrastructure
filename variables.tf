# =============================================================================
# Variáveis Globais — Root Module
# =============================================================================
# Mantém apenas variáveis usadas TRANSVERSALMENTE pelos módulos filhos
# (region, project, environment, tags). Variáveis específicas de módulo ficam
# em modules/<módulo>/variables.tf.
# =============================================================================

variable "region" {
  description = "Região AWS onde os recursos serão provisionados"
  type        = string
  default     = "us-east-1"
}

variable "project" {
  description = "Nome do projeto - usado em prefixos e tags"
  type        = string
  default     = "SolidaryTech"
}

variable "environment" {
  description = "Ambiente de deploy (dev, staging, prod) - propagado em todas as tags"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "O ambiente deve ser 'dev', 'staging' ou 'prod'."
  }
}

variable "cost_center" {
  description = "Centro de custos para tags FinOps"
  type        = string
  default     = "NGO-Core"
}

variable "owner" {
  description = "Time responsável pelos recursos (tag FinOps/Governança)"
  type        = string
  default     = "DevOps-Team"
}

# -----------------------------------------------------------------------------
# Credenciais AWS Academy (sessão temporária)
# -----------------------------------------------------------------------------
# Necessárias para passar como user_data ao bootstrap EC2.
# -----------------------------------------------------------------------------
variable "aws_access_key_id" {
  description = "AWS Access Key ID (sessão Academy)"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key (sessão Academy)"
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token (sessão Academy)"
  type        = string
  sensitive   = true
}
