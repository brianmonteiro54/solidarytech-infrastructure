# =============================================================================
# Platform Module — Variables
# =============================================================================
# EKS Cluster + Bootstrap (manifestos K8s aplicados via EC2 efêmera).
# =============================================================================

variable "name_prefix" {
  description = "Prefixo de nomeação"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS"
  type        = string
}

# -----------------------------------------------------------------------------
# Networking (do módulo networking)
# -----------------------------------------------------------------------------
variable "vpc_id" {
  description = "ID da VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "Subnets privadas para o cluster e workers"
  type        = list(string)
}

variable "workers_sg_id" {
  description = "Security Group dos EKS workers"
  type        = string
}

variable "vpn_sg_id" {
  description = "Security Group da VPN Pritunl (para liberar acesso ao API server)"
  type        = string
}

# -----------------------------------------------------------------------------
# IAM (AWS Academy: LabRole para tudo)
# -----------------------------------------------------------------------------
variable "cluster_role_arn" {
  description = "ARN da IAM Role do cluster (AWS Academy: LabRole)"
  type        = string
}

variable "node_role_arn" {
  description = "ARN da IAM Role dos nodes (AWS Academy: LabRole)"
  type        = string
}

# -----------------------------------------------------------------------------
# Configuração do Cluster
# -----------------------------------------------------------------------------
variable "cluster_version" {
  description = <<-EOT
    Versão do Kubernetes EKS. Padrão: 1.34
  EOT
  type        = string
  default     = "1.34"
}

variable "endpoint_private_access" {
  description = "Acesso privado ao API server (true em produção)"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Acesso público ao API server (false em produção; bootstrap acessa via VPC)"
  type        = bool
  default     = false
}

variable "enabled_cluster_log_types" {
  description = "Tipos de log do cluster habilitados (observability)"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

# -----------------------------------------------------------------------------
# Node Groups (workers)
# -----------------------------------------------------------------------------
variable "nodegroups" {
  description = <<-EOT
    Configuração dos node groups (managed). Schema do módulo upstream:
    scaling_min/scaling_max/scaling_desired (não desired_size/min_size/max_size).

    Padrão: 2 nodegroups, um por AZ (pinning via nodegroup_az_mapping).
    Cada nodegroup escala independentemente, permitindo balanceamento granular.
  EOT
  type        = any
  default = {
    "solidarytech-private-1a" = {
      scaling_desired = 1
      scaling_min     = 1
      scaling_max     = 4
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2023_x86_64_STANDARD"
    }
    "solidarytech-private-1b" = {
      scaling_desired = 1
      scaling_min     = 1
      scaling_max     = 4
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2023_x86_64_STANDARD"
    }
  }
}

variable "nodegroup_az_mapping" {
  description = "Pinning de nodegroup para subnet específica (índice no array private_subnet_ids)"
  type        = map(number)
  default = {
    "solidarytech-private-1a" = 0 # primeira subnet privada (AZ a)
    "solidarytech-private-1b" = 1 # segunda subnet privada (AZ b)
  }
}

# -----------------------------------------------------------------------------
# Launch Template (worker nodes)
# -----------------------------------------------------------------------------
variable "launch_template_instance_type" {
  description = "Tipo da instância dos workers (FinOps: t3.medium em dev)"
  type        = string
  default     = "t3.medium"
}

variable "launch_template_volume_size" {
  description = "Tamanho do disco EBS dos workers (GB)"
  type        = number
  default     = 60
}

# -----------------------------------------------------------------------------
# Addons (instalados pelo EKS, não pelo bootstrap)
# -----------------------------------------------------------------------------
variable "addons" {
  description = "Mapa de addons EKS. IMPORTANTE: a chave do map vira o addon_name na AWS, então use hífens (vpc-cni, kube-proxy) não underscores."
  type        = any
  default = {
    # Chaves DEVEM ser os nomes oficiais da AWS (com hífen!)
    # Ref: aws_eks_addon.this usa each.key como addon_name no módulo upstream
    "vpc-cni" = {
      addon_version = null
    }
    coredns = {
      addon_version = null
    }
    "kube-proxy" = {
      addon_version = null
    }
  }
}

# -----------------------------------------------------------------------------
# Bootstrap — Credenciais Academy (limitação do ambiente)
# -----------------------------------------------------------------------------
variable "aws_access_key_id" {
  description = "AWS Access Key ID (sessão Academy)"
  type        = string
  sensitive   = true
}

variable "aws_secret_access_key" {
  description = "AWS Secret Access Key (sessão Academy)"
  type        = string
  sensitive   = true
}

variable "aws_session_token" {
  description = "AWS Session Token (sessão Academy)"
  type        = string
  sensitive   = true
}
