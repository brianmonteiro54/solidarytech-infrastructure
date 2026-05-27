# =============================================================================
# Databases — RDS (PostgreSQL) + DynamoDB
# =============================================================================
# RDS: cria UM por entrada em var.rds_databases (for_each), eliminando
#      a repetição de blocos. Em ToggleMaster havia 3 blocos idênticos —
#      aqui temos 1 bloco que escala para qualquer nº de bancos.
#
# DynamoDB: tabela única para volunteer-service (Partition Key: volunteer_id).
# =============================================================================

# -----------------------------------------------------------------------------
# RDS (for_each: ngo_db, donation_db)
# -----------------------------------------------------------------------------
module "rds" {
  for_each = var.rds_databases

  source = "github.com/brianmonteiro54/terraform-aws-rds-database//modules/rds?ref=d4a0e3993842e0876d3d918573ff895145befa2a"

  # --- Identificação ---
  db_identifier = each.value.identifier
  db_name       = each.value.db_name
  environment   = var.environment

  # --- Engine ---
  engine         = var.rds_engine
  engine_version = var.rds_engine_version
  instance_class = var.rds_instance_class
  username       = var.rds_username
  port           = var.rds_port

  # --- Senha gerenciada pelo AWS Secrets Manager (não fica no state!) ---
  manage_master_user_password = true

  # --- Networking ---
  subnet_ids            = var.private_subnet_ids
  create_subnet_group   = true
  create_security_group = true
  vpc_id                = var.vpc_id
  publicly_accessible   = false

  # --- Ingress: APENAS do SG dos EKS workers ---
  security_group_ingress_rules = [
    {
      from_port                = var.rds_port
      to_port                  = var.rds_port
      protocol                 = "tcp"
      source_security_group_id = var.allowed_sg_id
      description              = "Allow PostgreSQL from EKS workers"
    }
  ]

  # --- Storage ---
  allocated_storage     = var.rds_allocated_storage
  max_allocated_storage = var.rds_max_allocated_storage
  storage_type          = var.rds_storage_type
  storage_encrypted     = var.rds_storage_encrypted

  # --- HA + Backup ---
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_period
  skip_final_snapshot     = var.rds_skip_final_snapshot
  deletion_protection     = var.rds_deletion_protection

  tags = {
    Service = each.value.service
  }
}

# -----------------------------------------------------------------------------
# DynamoDB — Volunteers
# -----------------------------------------------------------------------------
module "dynamodb_volunteers" {
  # TODO: substituir ?ref=main por hash imutável após git ls-remote (boa prática mostrada na Fase 2)
  source = "github.com/brianmonteiro54/terraform-aws-dynamodb//modules/dynamodb?ref=main"

  table_name        = var.dynamodb_table_name
  table_name_prefix = var.name_prefix
  environment       = var.environment

  # --- Schema ---
  hash_key   = "volunteer_id"
  attributes = [
    {
      name = "volunteer_id"
      type = "S" # String (UUID)
    }
  ]

  # --- Billing (FinOps: PAY_PER_REQUEST = paga por uso real, sem provisioning) ---
  billing_mode = var.dynamodb_billing_mode

  # --- Encryption + DR ---
  enable_encryption              = true
  point_in_time_recovery_enabled = var.dynamodb_pitr_enabled

  tags = {
    Service = "volunteer-service"
  }
}
