# =============================================================================
# Databases Module — Variables
# =============================================================================
# Consolida RDS (para ngo e donation) e DynamoDB (para volunteer).
# RDS usa for_each — adicionar/remover bancos editando o map.
# =============================================================================

variable "name_prefix" {
  description = "Prefixo de nomeação"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

# -----------------------------------------------------------------------------
# Networking (recebido do módulo networking)
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID da VPC onde os RDS serão criados"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas para o DB subnet group"
  type        = list(string)
}

variable "allowed_sg_id" {
  description = "Security Group ID autorizado a acessar os RDS (geralmente eks_workers_sg)"
  type        = string
}

# -----------------------------------------------------------------------------
# RDS — Configuração (compartilhada entre todos os RDS)
# -----------------------------------------------------------------------------
variable "rds_databases" {
  description = <<-EOT
    Map de bancos RDS a criar. Chave = identificador lógico, valor = config.
    Estrutura:
      {
        ngo = {
          identifier = "solidarytech-dev-ngo-db"
          db_name    = "ngo_db"
          service    = "ngo-service"
        }
        donation = { ... }
      }
  EOT
  type = map(object({
    identifier = string
    db_name    = string
    service    = string
  }))
}

variable "rds_engine" {
  description = "Engine de banco (postgres, mysql, etc)"
  type        = string
  default     = "postgres"
}

variable "rds_engine_version" {
  description = "Versão da engine PostgreSQL (15.17 é a versão mais recente da major 15.x em mai/2026)"
  type        = string
  default     = "15.17"
}

variable "rds_instance_class" {
  description = "Tipo da instância RDS (FinOps: db.t3.micro em dev, db.t3.small+ em prod)"
  type        = string
  default     = "db.t3.micro"
}

variable "rds_username" {
  description = "Username do master user"
  type        = string
  default     = "postgres"
}

variable "rds_allocated_storage" {
  description = "Storage inicial em GB"
  type        = number
  default     = 20
}

variable "rds_max_allocated_storage" {
  description = "Auto-scaling max em GB (FinOps: limita custo de storage runaway)"
  type        = number
  default     = 50
}

variable "rds_storage_type" {
  description = "Tipo de storage (gp3, gp2, io1)"
  type        = string
  default     = "gp3"
}

variable "rds_storage_encrypted" {
  description = "Criptografia at-rest (deve ser true em todos os ambientes)"
  type        = bool
  default     = true
}

variable "rds_multi_az" {
  description = "Multi-AZ standby (FinOps: false em dev, true em prod)"
  type        = bool
  default     = false
}

variable "rds_backup_retention_period" {
  description = "Dias de retenção de backup (FinOps + DR)"
  type        = number
  default     = 7
}

variable "rds_skip_final_snapshot" {
  description = "Pula snapshot final na destruição (dev: true, prod: false)"
  type        = bool
  default     = true
}

variable "rds_deletion_protection" {
  description = "Protege contra deleção acidental (recomendado true em prod)"
  type        = bool
  default     = false
}

variable "rds_port" {
  description = "Porta do banco"
  type        = number
  default     = 5432
}

# -----------------------------------------------------------------------------
# DynamoDB — Volunteers
# -----------------------------------------------------------------------------
# Nome da tabela é fixo ("volunteers") + prefix aplicado pelo módulo upstream.
# Resultado final: "${name_prefix}-volunteers" (ex: solidarytech-prod-volunteers)
# -----------------------------------------------------------------------------

variable "dynamodb_billing_mode" {
  description = "PAY_PER_REQUEST (FinOps friendly) ou PROVISIONED"
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Deve ser 'PAY_PER_REQUEST' ou 'PROVISIONED'."
  }
}

variable "dynamodb_pitr_enabled" {
  description = "Point-In-Time Recovery (DR: backup contínuo até 35 dias)"
  type        = bool
  default     = true
}
