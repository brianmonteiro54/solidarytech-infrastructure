# =============================================================================
# Backend Remoto — S3 com Lock Nativo
# =============================================================================
# Configuração vazia propositalmente. Os valores reais são injetados via
# arquivo .hcl por ambiente:
#
#   terraform init -backend-config=envs/dev/backend.hcl
#   terraform init -backend-config=envs/prod/backend.hcl
#
# Lock nativo via S3 (use_lockfile=true) — disponível desde Terraform 1.10.
# A configuração `dynamodb_table` foi DEPRECADA pela HashiCorp em favor de
# conditional writes no próprio S3 (sem custo extra, sem recurso adicional).
#
# Isso permite que múltiplos ambientes compartilhem o mesmo código e usem
# estados separados (bucket/key distintos por ambiente).
# =============================================================================

terraform {
  backend "s3" {
    # Valores preenchidos via -backend-config (envs/<env>/backend.hcl)
  }
}
