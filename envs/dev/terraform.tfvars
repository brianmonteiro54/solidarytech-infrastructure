# =============================================================================
# DEV Environment — Variáveis
# =============================================================================
# Apenas valores que DIFEREM dos defaults. Os defaults dos módulos já são
# adequados para dev (FinOps friendly).
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
# Credenciais AWS Academy
# -----------------------------------------------------------------------------
# IMPORTANTE: NUNCA commitar este arquivo com valores reais.
# Use variáveis de ambiente em CI/CD:
#   export TF_VAR_aws_access_key_id="..."
#   export TF_VAR_aws_secret_access_key="..."
#   export TF_VAR_aws_session_token="..."
#
# Ou crie um arquivo `secrets.auto.tfvars` (que está no .gitignore)
# -----------------------------------------------------------------------------
# aws_access_key_id     = ""
# aws_secret_access_key = ""
# aws_session_token     = ""
