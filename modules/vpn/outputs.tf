# =============================================================================
# VPN Module — Outputs
# =============================================================================

output "instance_id" {
  description = "ID da instância EC2 da VPN"
  value       = module.pritunl_vpn.instance_id
}

output "public_ip" {
  description = "IP público da VPN (Elastic IP se create_eip=true)"
  value       = coalesce(module.pritunl_vpn.eip_public_ip, module.pritunl_vpn.instance_public_ip)
}

output "security_group_id" {
  description = "Security Group da VPN (consumido por outros módulos para liberar acesso)"
  value       = module.pritunl_vpn.security_group_id
}

output "admin_url" {
  description = "URL do painel administrativo do Pritunl"
  value       = "https://${coalesce(module.pritunl_vpn.eip_public_ip, module.pritunl_vpn.instance_public_ip)}"
}
