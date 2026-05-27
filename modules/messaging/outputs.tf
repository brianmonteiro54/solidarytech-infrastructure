# =============================================================================
# Messaging Module — Outputs
# =============================================================================

output "queue_url" {
  description = "URL da fila principal de doações"
  value       = module.sqs_donations.queue_url
}

output "queue_arn" {
  description = "ARN da fila principal de doações"
  value       = module.sqs_donations.queue_arn
}

output "queue_name" {
  description = "Nome completo da fila principal"
  value       = module.sqs_donations.queue_name
}

output "dlq_url" {
  description = "URL da Dead Letter Queue"
  value       = module.sqs_donations.dlq_url
}

output "dlq_arn" {
  description = "ARN da Dead Letter Queue"
  value       = module.sqs_donations.dlq_arn
}

output "alarm_dlq_arn" {
  description = "ARN do alarme CloudWatch da DLQ (input para a Etapa 5 - SRE Dashboard)"
  value       = module.sqs_donations.alarm_dlq_messages_arn
}
