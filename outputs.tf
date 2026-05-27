# =============================================================================
# Outputs Agregados — Root Module
# =============================================================================
# Expõe valores úteis para automação externa (CI/CD, kubectl, scripts de
# deploy de aplicação).
# =============================================================================

# -----------------------------------------------------------------------------
# Networking
# -----------------------------------------------------------------------------
output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.networking.vpc_id
}

output "private_subnet_ids" {
  description = "Subnets privadas (onde rodam EKS workers, RDS, etc)"
  value       = module.networking.private_subnet_ids
}

output "public_subnet_ids" {
  description = "Subnets públicas (ELB, NAT, VPN)"
  value       = module.networking.public_subnet_ids
}

# -----------------------------------------------------------------------------
# EKS
# -----------------------------------------------------------------------------
output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.platform.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API server do EKS (privado neste setup)"
  value       = module.platform.cluster_endpoint
  sensitive   = true
}

# -----------------------------------------------------------------------------
# Registry
# -----------------------------------------------------------------------------
output "ecr_repository_urls" {
  description = "URLs dos repositórios ECR por microsserviço"
  value       = module.registry.repository_urls
}

# -----------------------------------------------------------------------------
# Databases
# -----------------------------------------------------------------------------
output "rds_endpoints" {
  description = "Endpoints dos bancos RDS (mapeados por serviço)"
  value       = module.databases.rds_endpoints
  sensitive   = true
}

output "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB de voluntários"
  value       = module.databases.dynamodb_table_name
}

# -----------------------------------------------------------------------------
# Messaging
# -----------------------------------------------------------------------------
output "sqs_donations_url" {
  description = "URL da fila SQS principal de doações"
  value       = module.messaging.queue_url
}

output "sqs_donations_dlq_url" {
  description = "URL da Dead Letter Queue de doações"
  value       = module.messaging.dlq_url
}

# -----------------------------------------------------------------------------
# VPN
# -----------------------------------------------------------------------------
output "vpn_public_ip" {
  description = "IP público do servidor VPN Pritunl"
  value       = module.vpn.public_ip
}
