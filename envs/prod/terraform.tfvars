# =============================================================================
# PROD Environment — Variáveis
# =============================================================================
# Ambiente de produção. Foco em HA + Segurança (não FinOps):
#   - 2 NAT Gateways (1 por AZ, sem SPOF na rede)
#   - RDS Multi-AZ ligado (standby em outra AZ)
#   - Deletion protection ligado
#   - Snapshots finais habilitados
#   - Backup retention estendido
# =============================================================================

# -----------------------------------------------------------------------------
# Identificação
# -----------------------------------------------------------------------------
region      = "us-east-1"
project     = "SolidaryTech"
environment = "prod"
cost_center = "NGO-Core"
owner       = "DevOps-Team"

# -----------------------------------------------------------------------------
# Networking (HA, NÃO FinOps)
# -----------------------------------------------------------------------------
enable_nat_gateway = true
single_nat_gateway = false # ← 1 NAT por AZ (HA, ~$64/mês mas sem SPOF)

# -----------------------------------------------------------------------------
# Credenciais AWS Academy
# -----------------------------------------------------------------------------
# IMPORTANTE: NUNCA commitar com valores reais. Use GitHub Secrets.
# -----------------------------------------------------------------------------
# aws_access_key_id     = ""
# aws_secret_access_key = ""
# aws_session_token     = ""

# -----------------------------------------------------------------------------
# Production-grade overrides (descomente conforme necessidade)
# -----------------------------------------------------------------------------
# Os defaults dos módulos são FinOps-friendly. Em PROD vale ativar:
#
# RDS — Multi-AZ + proteção (requer ajuste em modules/databases/variables.tf)
#   rds_multi_az                = true   # Standby síncrono em outra AZ
#   rds_instance_class          = "db.t3.small"
#   rds_max_allocated_storage   = 100
#   rds_skip_final_snapshot     = false  # Sempre tira snapshot ao destruir
#   rds_deletion_protection     = true   # Proteção contra delete acidental
#   rds_backup_retention_period = 14     # 14 dias de backup
