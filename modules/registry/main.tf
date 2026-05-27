# =============================================================================
# Registry — ECR Repositories (for_each)
# =============================================================================
# Substitui a abordagem antiga de 5 blocos repetidos por UM bloco com for_each.
# Adicionar ou remover um microsserviço se torna trivial — basta editar
# a lista `microservices` no root module.
# =============================================================================

module "ecr" {
  # checkov:skip=CKV_AWS_163:Scan habilitado por var.scan_on_push (default true)
  for_each = toset(var.microservices)

  source = "github.com/brianmonteiro54/terraform-aws-ecr//modules/ecr?ref=2c4973a14fc5d908e6d9c534d46a453a18d29206"

  # --- Identificação ---
  repository_name        = each.value
  repository_name_prefix = var.name_prefix
  environment            = var.environment

  # --- Configuração de Imagem ---
  image_tag_mutability = var.image_tag_mutability
  scan_on_push         = var.scan_on_push

  # --- Lifecycle (FinOps) ---
  create_lifecycle_policy          = true
  enable_lifecycle_untagged_images = true
  lifecycle_untagged_days          = var.lifecycle_untagged_days
  enable_lifecycle_tagged_images   = true
  lifecycle_tagged_count           = var.lifecycle_tagged_count

  # --- Encryption (default AES256 já protege; KMS adicionado em prod) ---
  enable_encryption = true
  create_kms_key    = false

  # --- IAM ---
  # AWS Academy: políticas IAM não podem ser criadas pelo terraform.
  # Aplicação consome via LabRole anexada às pods/nodes.
  create_iam_policies      = false
  create_repository_policy = false

  tags = {
    Service = each.value
  }
}
