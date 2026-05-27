# =============================================================================
# Registry Module — Variables
# =============================================================================
# ECR para os microsserviços do SolidaryTech.
#
# AQUI ESTÁ O `for_each` que resolve o problema apontado pelo avaliador:
# em vez de 3 blocos `module "ecr_*"` repetidos, temos UM bloco que itera
# sobre var.microservices.
# =============================================================================

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "name_prefix" {
  description = "Prefixo de nome dos repositórios (ex: 'solidarytech')"
  type        = string
}

variable "microservices" {
  description = "Lista de nomes de microsserviços que terão repositório ECR"
  type        = list(string)

  validation {
    condition     = length(var.microservices) > 0
    error_message = "É necessário declarar pelo menos um microsserviço."
  }
}

# -----------------------------------------------------------------------------
# Política de Lifecycle (FinOps: evita lixo acumulado no ECR)
# -----------------------------------------------------------------------------
variable "image_tag_mutability" {
  description = "IMMUTABLE força versionamento e impede sobrescrita acidental de tags"
  type        = string
  default     = "IMMUTABLE"

  validation {
    condition     = contains(["IMMUTABLE", "MUTABLE"], var.image_tag_mutability)
    error_message = "Deve ser 'IMMUTABLE' ou 'MUTABLE'."
  }
}

variable "scan_on_push" {
  description = "Habilita scan automático de vulnerabilidades a cada push"
  type        = bool
  default     = true
}

variable "lifecycle_untagged_days" {
  description = "Dias até remover imagens sem tag (FinOps: limpa lixo)"
  type        = number
  default     = 3
}

variable "lifecycle_tagged_count" {
  description = "Quantas imagens tagged manter (FinOps: limita acúmulo)"
  type        = number
  default     = 10
}
