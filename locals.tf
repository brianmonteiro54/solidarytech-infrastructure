# =============================================================================
# Locals — Constantes Calculadas e Tags Padronizadas
# =============================================================================
# Centraliza tudo o que é "calculado a partir de variáveis" para que os módulos
# filhos não precisem recalcular nada. Tags FinOps obrigatórias ficam aqui.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Tags FinOps Obrigatórias
  # ---------------------------------------------------------------------------
  # Aplicadas automaticamente em TODOS os recursos via default_tags do provider.
  # Cobrem os 5 pilares de FinOps: Identificação, Ambiente, Custo, Propriedade
  # e Origem (ManagedBy).
  # ---------------------------------------------------------------------------
  common_tags = {
    Project     = var.project
    Environment = var.environment
    CostCenter  = var.cost_center
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }

  # ---------------------------------------------------------------------------
  # Prefixo Padronizado de Nomes
  # ---------------------------------------------------------------------------
  # Exemplo: solidarytech-dev, solidarytech-prod
  # Usado para nomear recursos de forma previsível e idempotente.
  # ---------------------------------------------------------------------------
  name_prefix = "${lower(var.project)}-${var.environment}"

  # ---------------------------------------------------------------------------
  # Microsserviços do SolidaryTech
  # ---------------------------------------------------------------------------
  # Lista única usada como source-of-truth pelo ECR (for_each).
  # Adicionar/remover um microsserviço aqui se reflete automaticamente.
  # ---------------------------------------------------------------------------
  microservices = [
    "ngo-service",
    "donation-service",
    "volunteer-service",
  ]

  # ---------------------------------------------------------------------------
  # Bancos PostgreSQL (RDS)
  # ---------------------------------------------------------------------------
  # Configuração específica por banco. Compartilham engine/instance class
  # (definidos em variables do módulo databases), mas têm nomes próprios.
  # Volunteer-service NÃO usa RDS — usa DynamoDB (configurado no mesmo módulo).
  # ---------------------------------------------------------------------------
  rds_databases = {
    ngo = {
      identifier = "${local.name_prefix}-ngo-db"
      db_name    = "ngo_db"
      service    = "ngo-service"
    }
    donation = {
      identifier = "${local.name_prefix}-donation-db"
      db_name    = "donation_db"
      service    = "donation-service"
    }
  }
}
