# =============================================================================
# Bastion Module — Outputs
# =============================================================================

output "instance_id" {
  description = "ID da instância EC2 do bastion"
  value       = module.bastion.instance_id
}

output "public_ip" {
  description = "IP público do bastion (Elastic IP se create_eip=true)"
  value       = coalesce(module.bastion.eip_public_ip, module.bastion.instance_public_ip)
}

output "security_group_id" {
  description = "Security Group próprio do bastion"
  value       = module.bastion.security_group_id
}

output "ssh_command" {
  description = "Comando SSH para o bastion (ajuste o caminho da chave)"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ubuntu@${coalesce(module.bastion.eip_public_ip, module.bastion.instance_public_ip)}"
}
