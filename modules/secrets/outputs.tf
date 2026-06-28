# =============================================================================
# Outputs — Módulo secrets
# =============================================================================

output "monitoring_secret_name" {
  description = "Nome do segredo de observabilidade no Secrets Manager."
  value       = var.create_monitoring_secret ? aws_secretsmanager_secret.monitoring[0].name : null
}

output "monitoring_secret_arn" {
  description = "ARN do segredo de observabilidade."
  value       = var.create_monitoring_secret ? aws_secretsmanager_secret.monitoring[0].arn : null
}
