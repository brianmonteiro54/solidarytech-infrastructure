# =============================================================================
# Networking Module — Outputs
# =============================================================================

output "vpc_id" {
  description = "ID da VPC criada"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "Bloco CIDR da VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs das subnets públicas (NAT, ELB, VPN)"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs das subnets privadas (EKS workers, RDS)"
  value       = module.vpc.private_subnet_ids
}

output "eks_workers_sg_id" {
  description = "ID do Security Group dos EKS workers (consumido por RDS, EKS module)"
  value       = aws_security_group.eks_workers.id
}
