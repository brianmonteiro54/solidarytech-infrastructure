# =============================================================================
# PROD Environment — Variáveis
# =============================================================================
# Diferenças vs DEV: HA + deletion protection + multi-AZ + tipos maiores.
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
# Credenciais AWS Academy (injetar via CI/CD - NUNCA commitar valores)
# -----------------------------------------------------------------------------
# aws_access_key_id     = ""
# aws_secret_access_key = ""
# aws_session_token     = ""

# -----------------------------------------------------------------------------
# Overrides recomendados para PROD (não-default no módulo databases)
# -----------------------------------------------------------------------------
# Esses serão aplicados quando você refinar — agora ficam comentados
# para você poder ativar gradualmente:
#
# rds_multi_az            = true   # HA: standby em outra AZ
# rds_instance_class      = "db.t3.small"
# rds_max_allocated_storage = 100
# rds_skip_final_snapshot = false  # Snapshot antes de destruir
# rds_deletion_protection = true   # Proteção contra delete acidental
# rds_backup_retention_period = 14
