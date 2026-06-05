# =============================================================================
# Módulo: secrets — AWS Secrets Manager
# =============================================================================

resource "aws_secretsmanager_secret" "monitoring" {
  count = var.create_monitoring_secret ? 1 : 0

  name                    = var.monitoring_secret_name
  description             = "SolidaryTech — credenciais do stack de observabilidade (Grafana, Discord, PagerDuty, New Relic). Consumido via External Secrets."
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name      = var.monitoring_secret_name
    Component = "observability"
  }
}

resource "aws_secretsmanager_secret_version" "monitoring" {
  count = var.create_monitoring_secret ? 1 : 0

  secret_id = aws_secretsmanager_secret.monitoring[0].id

  # Chaves EXATAMENTE como o ExternalSecret do solidarytech-monitoring-gitops
  # espera (remoteRef.property: <KEY>). Mantemos todas as chaves presentes
  # (mesmo vazias) para não quebrar o lookup do External Secrets.
  secret_string = jsonencode({
    GRAFANA_ADMIN_USER     = var.grafana_admin_user
    GRAFANA_ADMIN_PASSWORD = var.grafana_admin_password
    DISCORD_WEBHOOK_URL    = var.discord_webhook_url
    PAGERDUTY_SERVICE_KEY  = var.pagerduty_service_key
    NEW_RELIC_API_KEY      = var.new_relic_api_key
  })

  lifecycle {
    # O valor é gerenciado fora do apply rotineiro (ver cabeçalho do módulo).
    # Impede que a CI (sem os valores sensíveis) sobrescreva o conteúdo real.
    ignore_changes = [secret_string]
  }
}
