# =============================================================================
# Módulo: secrets — AWS Secrets Manager
# =============================================================================

resource "aws_secretsmanager_secret" "monitoring" {
  count = var.create_monitoring_secret ? 1 : 0

  #checkov:skip=CKV_AWS_149
  #checkov:skip=CKV2_AWS_57:Segredo guarda tokens de terceiros (Grafana/Discord/PagerDuty/New Relic) sem rotação automática nativa
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
    token_github             = var.token_github
    DISCORD_WEBHOOK_URL    = var.discord_webhook_url
    PAGERDUTY_SERVICE_KEY  = var.pagerduty_service_key
    NEW_RELIC_API_KEY      = var.new_relic_api_key
    ANTHROPIC_API_KEY      = var.anthropic_api_key
  })

  lifecycle {
    # O valor é gerenciado fora do apply rotineiro (ver cabeçalho do módulo).
    # Impede que a CI (sem os valores sensíveis) sobrescreva o conteúdo real.
    ignore_changes = [secret_string]
  }
}

# =============================================================================
# Segredos de CONFIG das aplicações (donation / ngo) — consumidos via ESO
# =============================================================================
locals {
  # O endpoint do RDS costuma vir como "host:porta"; o split funciona nos dois
  # casos — se vier só o host, a porta cai no fallback 5432 (Postgres).
  donation_db_host = var.donation_db_endpoint != "" ? split(":", var.donation_db_endpoint)[0] : ""
  donation_db_port = try(split(":", var.donation_db_endpoint)[1], "5432")
  ngo_db_host      = var.ngo_db_endpoint != "" ? split(":", var.ngo_db_endpoint)[0] : ""
  ngo_db_port      = try(split(":", var.ngo_db_endpoint)[1], "5432")
}

# ---- solidarytech/donation-service ----
resource "aws_secretsmanager_secret" "donation" {
  count = var.create_app_secrets ? 1 : 0

  #checkov:skip=CKV_AWS_149:AWS Academy não permite KMS CMK; usa chave AWS-owned
  #checkov:skip=CKV2_AWS_57:Config de app (host/porta/nome/URL), sem rotação automática
  name                    = "solidarytech/donation-service"
  description             = "SolidaryTech — config do donation-service (DB + SQS). Consumido via External Secrets."
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name      = "solidarytech/donation-service"
    Component = "donation"
  }
}

resource "aws_secretsmanager_secret_version" "donation" {
  count = var.create_app_secrets ? 1 : 0

  secret_id = aws_secretsmanager_secret.donation[0].id

  # Chaves == remoteRef.property do ExternalSecret donation-service-config
  secret_string = jsonencode({
    DONATION_DB_HOST = local.donation_db_host
    DONATION_DB_PORT = local.donation_db_port
    DONATION_DB_NAME = var.donation_db_name
    DONATION_SQS_URL = var.donation_sqs_url
  })
}

# ---- solidarytech/ngo-service ----
resource "aws_secretsmanager_secret" "ngo" {
  count = var.create_app_secrets ? 1 : 0

  #checkov:skip=CKV_AWS_149:AWS Academy não permite KMS CMK; usa chave AWS-owned
  #checkov:skip=CKV2_AWS_57:Config de app (host/porta/nome), sem rotação automática
  name                    = "solidarytech/ngo-service"
  description             = "SolidaryTech — config do ngo-service (DB). Consumido via External Secrets."
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name      = "solidarytech/ngo-service"
    Component = "ngo"
  }
}

resource "aws_secretsmanager_secret_version" "ngo" {
  count = var.create_app_secrets ? 1 : 0

  secret_id = aws_secretsmanager_secret.ngo[0].id

  # Chaves == remoteRef.property do ExternalSecret ngo-service-config
  secret_string = jsonencode({
    NGO_DB_HOST = local.ngo_db_host
    NGO_DB_PORT = local.ngo_db_port
    NGO_DB_NAME = var.ngo_db_name
  })
}
