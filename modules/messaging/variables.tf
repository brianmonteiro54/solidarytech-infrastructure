# =============================================================================
# Messaging Module — Variables
# =============================================================================
# SQS para o donation-service (Hot Path).
# Inclui Dead Letter Queue + Alarme CloudWatch — práticas de SRE desde o dia 1.
# =============================================================================

variable "name_prefix" {
  description = "Prefixo de nomeação"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Configuração da Fila Principal
# -----------------------------------------------------------------------------
variable "queue_name" {
  description = "Nome lógico da fila (será prefixado com name_prefix)"
  type        = string
  default     = "donations"
}

variable "visibility_timeout_seconds" {
  description = "Tempo durante o qual a mensagem fica invisível após consumo"
  type        = number
  default     = 300
}

variable "message_retention_seconds" {
  description = "Tempo de retenção das mensagens (max 14 dias = 1209600)"
  type        = number
  default     = 345600 # 4 dias
}

variable "receive_wait_time_seconds" {
  description = "Long polling (0=short, 20=long polling = mais eficiente)"
  type        = number
  default     = 20
}

# -----------------------------------------------------------------------------
# Dead Letter Queue (DLQ)
# -----------------------------------------------------------------------------
variable "max_receive_count" {
  description = "Nº de tentativas antes de mover para DLQ"
  type        = number
  default     = 5
}

# -----------------------------------------------------------------------------
# CloudWatch Alarme
# -----------------------------------------------------------------------------
variable "dlq_alarm_threshold" {
  description = "Acima deste nº de mensagens na DLQ, o alarme dispara"
  type        = number
  default     = 1
}
