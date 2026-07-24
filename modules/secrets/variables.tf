# =============================================================================
# Variáveis — Módulo secrets
# =============================================================================

variable "create_monitoring_secret" {
  description = "Cria o segredo solidarytech/monitoring. Em conta AWS compartilhada por dev e prod, deixe true em APENAS UM ambiente — o segredo é único e referenciado pelo nome literal no GitOps."
  type        = bool
  default     = true
}

variable "monitoring_secret_name" {
  description = "Nome do segredo no Secrets Manager. Deve casar com o remoteRef.key do ExternalSecret (solidarytech/monitoring)."
  type        = string
  default     = "solidarytech/monitoring"
}

variable "recovery_window_in_days" {
  description = "Janela de recuperação ao destruir o segredo. 0 = exclusão imediata (conveniente em lab/dev); 7–30 recomendável em prod."
  type        = number
  default     = 0
}

# ---- Conteúdo do segredo (chaves esperadas pelo External Secrets) -----------
variable "grafana_admin_user" {
  description = "Usuário admin do Grafana (não sensível)."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Senha admin do Grafana. Forneça via TF_VAR_grafana_admin_password (nunca commit)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "token_github" {
  description = "Token GITHUB."
  type        = string
  default     = ""
  sensitive   = true
}

variable "discord_webhook_url" {
  description = "Webhook do Discord para alertas/self-healing. Opcional (vazio = sem notificação Discord)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "pagerduty_service_key" {
  description = "Service/Integration key do PagerDuty. Opcional."
  type        = string
  default     = ""
  sensitive   = true
}

variable "new_relic_api_key" {
  description = "API key do New Relic (export OTLP). Opcional (vazio = sem export para New Relic)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "anthropic_api_key" {
  description = "API key da Claude API (Anthropic) para o resumo de incidentes com GenAI no self-healing. Opcional."
  type        = string
  default     = ""
  sensitive   = true
}

# =============================================================================
# Segredos de CONFIG das aplicações (consumidos via External Secrets)
# =============================================================================
# Diferente do monitoring (valores sensíveis, setados fora do apply), estes são
# CONFIG derivada de outros módulos (endpoint do RDS, URL do SQS). Portanto o
# Terraform os mantém em sincronia — SEM ignore_changes.
# As chaves do JSON batem EXATAMENTE com o remoteRef.property dos ExternalSecrets
# donation-service-config / ngo-service-config.
# =============================================================================

variable "create_app_secrets" {
  description = "Cria solidarytech/donation-service e solidarytech/ngo-service. Em conta AWS compartilhada dev/prod, deixe true em APENAS UM ambiente (os nomes são globais)."
  type        = bool
  default     = true
}

variable "donation_db_endpoint" {
  description = "Endpoint do RDS donation (host ou host:porta). Fonte: module.databases.rds_endpoints[\"donation\"]."
  type        = string
  default     = ""
  sensitive   = true
}

variable "donation_db_name" {
  description = "Nome do database donation. Fonte: module.databases.rds_db_names[\"donation\"]."
  type        = string
  default     = "donation_db"
}

variable "donation_sqs_url" {
  description = "URL da fila SQS de doações. Fonte: module.messaging.queue_url."
  type        = string
  default     = ""
}

variable "ngo_db_endpoint" {
  description = "Endpoint do RDS ngo (host ou host:porta). Fonte: module.databases.rds_endpoints[\"ngo\"]."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ngo_db_name" {
  description = "Nome do database ngo. Fonte: module.databases.rds_db_names[\"ngo\"]."
  type        = string
  default     = "ngo_db"
}
