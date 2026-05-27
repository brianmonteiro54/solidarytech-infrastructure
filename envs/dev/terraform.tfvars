# =============================================================================
# DEV Environment — Variáveis
# =============================================================================
# Ambiente de desenvolvimento. Otimizado para FinOps:
#   - 1 NAT Gateway (vs 2 em prod)
#   - Multi-AZ desligado nos RDS
#   - Deletion protection desligado
# =============================================================================

# -----------------------------------------------------------------------------
# Identificação
# -----------------------------------------------------------------------------
region      = "us-east-1"
project     = "SolidaryTech"
environment = "dev"
cost_center = "NGO-Core"
owner       = "DevOps-Team"

# -----------------------------------------------------------------------------
# Networking (FinOps)
# -----------------------------------------------------------------------------
enable_nat_gateway = true
single_nat_gateway = true # ← 1 NAT só (economiza ~$32/mês vs HA)

# -----------------------------------------------------------------------------
# Deletion Protection (DEV: tudo desligado pra permitir destroy rápido)
# -----------------------------------------------------------------------------
cluster_deletion_protection = false
rds_deletion_protection     = false

# -----------------------------------------------------------------------------
# Credenciais AWS Academy
# -----------------------------------------------------------------------------
# IMPORTANTE: NUNCA commitar com valores reais. Use:
#   - GitHub Secrets em CI/CD (recomendado)
#   - Variáveis de ambiente: TF_VAR_aws_access_key_id="..."
#   - secrets.auto.tfvars (no .gitignore)
# -----------------------------------------------------------------------------
# aws_access_key_id     = ""
# aws_secret_access_key = ""
# aws_session_token     = ""
