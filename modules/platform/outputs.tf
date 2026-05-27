# =============================================================================
# Platform Module — Outputs
# =============================================================================

output "cluster_name" {
  description = "Nome do cluster EKS"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint do API server (privado neste setup)"
  value       = module.eks.cluster_endpoint
  sensitive   = true
}

output "cluster_security_group_id" {
  description = "Security Group do control plane"
  value       = module.eks.cluster_security_group_id
}

output "cluster_certificate_authority_data" {
  description = "CA do cluster (para kubeconfig)"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "kubeconfig_command" {
  description = "Comando para gerar kubeconfig local (via VPN)"
  value       = module.eks.kubeconfig_command
}
