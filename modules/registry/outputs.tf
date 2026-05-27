# =============================================================================
# Registry Module — Outputs
# =============================================================================

output "repository_urls" {
  description = "URLs dos repositórios ECR mapeados por microsserviço"
  value       = { for k, v in module.ecr : k => v.repository_url }
}

output "repository_arns" {
  description = "ARNs dos repositórios ECR mapeados por microsserviço"
  value       = { for k, v in module.ecr : k => v.repository_arn }
}

output "repository_names" {
  description = "Lista de nomes completos (com prefix) dos repositórios criados"
  value       = [for v in module.ecr : v.repository_name]
}
