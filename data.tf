# =============================================================================
# Data Sources Globais
# =============================================================================
# Recursos AWS que são CONSUMIDOS (não criados) pelo Terraform.
# Concentrados aqui para reuso pelos módulos filhos.
# =============================================================================

# -----------------------------------------------------------------------------
# LabRole — AWS Academy
# -----------------------------------------------------------------------------
# Role pré-existente no ambiente Academy. Limitações:
#   - Não podemos criar IAM Roles/Policies novas
#   - Não podemos criar OIDC provider (sem IRSA)
#   - Não podemos criar Instance Profiles além de LabInstanceProfile
# Por isso, EKS e bootstrap EC2 reutilizam esta role.
# -----------------------------------------------------------------------------
data "aws_iam_role" "lab_role" {
  name = "LabRole"
}

# -----------------------------------------------------------------------------
# Caller Identity (account_id e ARN da sessão atual)
# -----------------------------------------------------------------------------
data "aws_caller_identity" "current" {}

# -----------------------------------------------------------------------------
# Availability Zones disponíveis na região
# -----------------------------------------------------------------------------
# O módulo VPC usa este data source para distribuir subnets dinamicamente.
# Excluímos LocalZones (only=opt-in-not-required) que cobram mais caro.
# -----------------------------------------------------------------------------
data "aws_availability_zones" "available" {
  state = "available"

  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
