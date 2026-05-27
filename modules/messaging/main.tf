# =============================================================================
# Messaging — SQS Donations (Hot Path)
# =============================================================================
# Fila principal: solidary-donations
# Backup: DLQ automática (mensagens após 5 falhas vão pra DLQ)
# Observability: Alarme CloudWatch dispara se DLQ tem mensagens
#                (sinal de problema no consumidor — entrada pro Error Budget)
# =============================================================================

module "sqs_donations" {
  # checkov:skip=CKV_AWS_27:KMS desabilitado em Academy (LabRole sem permissão)
  # TODO: substituir ?ref=main por hash imutável após git ls-remote (boa prática mostrada na Fase 2)
  source = "github.com/brianmonteiro54/terraform-aws-sqs//modules/sqs?ref=474eeb54ac7af491c1d921a6d78746cf920647c2"

  # --- Identificação ---
  queue_name        = var.queue_name
  queue_name_prefix = var.name_prefix
  environment       = var.environment

  # --- Configuração da Fila Principal ---
  fifo_queue                 = false
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # --- Encryption (SQS-managed SSE; Academy não permite KMS) ---
  enable_encryption   = true
  use_sqs_managed_sse = true
  create_kms_key      = false

  # --- Dead Letter Queue (SRE: protege contra mensagens "poison pill") ---
  create_dlq                    = true
  max_receive_count             = var.max_receive_count
  dlq_message_retention_seconds = 1209600 # 14 dias (máximo) - mais tempo para investigar

  # --- IAM Policies (Academy: não criamos) ---
  create_queue_policy = false
  create_dlq_policy   = false

  # --- CloudWatch Alarms (SRE: sinal para Error Budget) ---
  enable_cloudwatch_alarms = true

  alarm_dlq_messages = {
    enabled             = true
    threshold           = var.dlq_alarm_threshold
    evaluation_periods  = 1
    period              = 60
    statistic           = "Maximum"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    treat_missing_data  = "notBreaching"
    description         = "Alerta: mensagens chegaram à DLQ - consumer pode estar falhando"
  }

  # Alarme de idade da mensagem mais antiga: indica que consumer está lento
  alarm_age_of_oldest_message = {
    enabled             = true
    threshold           = 600 # 10 minutos
    evaluation_periods  = 2
    period              = 60
    statistic           = "Maximum"
    comparison_operator = "GreaterThanThreshold"
    treat_missing_data  = "notBreaching"
    description         = "Alerta: mensagem na fila há mais de 10 min - consumer pode estar parado"
  }
}
