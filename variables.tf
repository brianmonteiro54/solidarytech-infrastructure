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
# Networking — NAT Gateway (FinOps)
# -----------------------------------------------------------------------------
# Por ambiente:
#   dev  → single_nat_gateway = true   (1 NAT, ~$32/mês, sem HA)
#   prod → single_nat_gateway = false  (2 NATs, ~$64/mês, HA entre AZs)
# -----------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Habilita NAT Gateway para acesso outbound das subnets privadas"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "true = 1 NAT (FinOps, dev); false = 1 NAT por AZ (HA, prod)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Deletion Protection (recursos críticos)
# -----------------------------------------------------------------------------
# Por ambiente:
#   dev  → false  (permite destroy rápido)
#   prod → true   (protege contra destroy acidental do cluster/RDS)
# -----------------------------------------------------------------------------
variable "cluster_deletion_protection" {
  description = "Proteção contra exclusão acidental do cluster EKS (true em prod)"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# CloudWatch Logs — Retenção do control plane do EKS
# -----------------------------------------------------------------------------
#   dev  → janela curta (FinOps; logs de debug de curto prazo bastam)
#   prod → janela estendida (auditoria/compliance)
# Evita o default da AWS de "nunca expirar" em /aws/eks/<cluster>/cluster.
# -----------------------------------------------------------------------------
variable "cluster_log_retention_in_days" {
  description = "Dias de retenção dos logs do control plane do EKS no CloudWatch (0 = nunca expira)"
  type        = number
  default     = 30
}

variable "rds_deletion_protection" {
  description = "Proteção contra exclusão acidental dos bancos RDS (true em prod)"
  type        = bool
  default     = false
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

# -----------------------------------------------------------------------------
# Observabilidade — segredo solidarytech/monitoring (Secrets Manager)
# -----------------------------------------------------------------------------
variable "grafana_admin_user" {
  description = "Usuário admin do Grafana"
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Senha admin do Grafana (TF_VAR_grafana_admin_password)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "Discord webhook para alertas/self-healing (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_service_key" {
  description = "PagerDuty service/integration key (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "new_relic_api_key" {
  description = "New Relic API key para export OTLP (opcional)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "API key da Claude API (Anthropic) para o resumo de incidentes com GenAI no self-healing (AIOps). Opcional."
  type        = string
  default     = ""
  sensitive   = true
}
