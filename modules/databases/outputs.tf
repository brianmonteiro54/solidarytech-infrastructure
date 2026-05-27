# =============================================================================
# Databases Module — Outputs
# =============================================================================

# -----------------------------------------------------------------------------
# RDS
# -----------------------------------------------------------------------------
output "rds_endpoints" {
  description = "Endpoints dos bancos RDS por serviço (sensitive)"
  value       = { for k, v in module.rds : k => v.db_instance_endpoint }
  sensitive   = true
}

output "rds_secret_arns" {
  description = "ARNs dos segredos do Secrets Manager com a senha de cada banco"
  value       = { for k, v in module.rds : k => v.master_user_secret_arn }
  sensitive   = true
}

output "rds_db_names" {
  description = "Nomes dos databases por serviço"
  value       = { for k, v in module.rds : k => v.db_instance_name }
}

output "rds_identifiers" {
  description = "Identificadores RDS por serviço"
  value       = { for k, v in module.rds : k => v.db_instance_identifier }
}

# -----------------------------------------------------------------------------
# DynamoDB
# -----------------------------------------------------------------------------
output "dynamodb_table_name" {
  description = "Nome final da tabela DynamoDB"
  value       = module.dynamodb_volunteers.table_name
}

output "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB"
  value       = module.dynamodb_volunteers.table_arn
}
