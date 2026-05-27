# =============================================================================
# Networking Module — Variables
# =============================================================================
# VPC + Security Groups consolidados num módulo lógico.
# =============================================================================

variable "name_prefix" {
  description = "Prefixo padronizado para nomeação de recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS - usado nas tags Kubernetes obrigatórias das subnets"
  type        = string
}

# -----------------------------------------------------------------------------
# CIDR da VPC
# -----------------------------------------------------------------------------
variable "vpc_cidr" {
  description = "Bloco CIDR principal da VPC"
  type        = string
  default     = "10.0.0.0/20"
}

variable "max_availability_zones" {
  description = "Número máximo de AZs a serem usadas (subnets serão criadas em todas)"
  type        = number
  default     = 2
}

variable "subnet_newbits" {
  description = "Bits adicionados ao CIDR da VPC para calcular subnets"
  type        = number
  default     = 4
}

# -----------------------------------------------------------------------------
# NAT Gateway (FinOps: single_nat_gateway=true em dev economiza ~$32/mês)
# -----------------------------------------------------------------------------
variable "enable_nat_gateway" {
  description = "Criar NAT Gateway para acesso outbound das subnets privadas"
  type        = bool
  default     = true
}

variable "single_nat_gateway" {
  description = "Usar um único NAT (FinOps: economiza em dev; trocar para false em prod multi-AZ)"
  type        = bool
  default     = true
}
