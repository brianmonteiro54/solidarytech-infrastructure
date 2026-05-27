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
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.31"
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
  description = "Configuração dos node groups (managed). Schema do módulo upstream: scaling_min/scaling_max/scaling_desired."
  type        = any
  default     = {
    workers = {
      scaling_desired = 2
      scaling_min     = 2
      scaling_max     = 4
      capacity_type   = "ON_DEMAND"
      ami_type        = "AL2_x86_64"
    }
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
  description = "Mapa de addons EKS (vpc-cni, coredns, kube-proxy, ebs-csi)"
  type        = any
  default     = {
    vpc_cni = {
      addon_name    = "vpc-cni"
      addon_version = null
    }
    coredns = {
      addon_name    = "coredns"
      addon_version = null
    }
    kube_proxy = {
      addon_name    = "kube-proxy"
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
