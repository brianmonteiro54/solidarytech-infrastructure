# =============================================================================
# Bastion Module — Variables
# =============================================================================
# EC2 ÚNICA e persistente que acumula duas funções:
#   1. Bastion host (SSH jump host) para alcançar o EKS/RDS privados
#   2. Bootstrap da plataforma K8s via user_data (kubectl/helm/ArgoCD/etc.)
#
# Substitui o antigo módulo `bootstrap` (EC2 efêmera). Sem VPN/Pritunl.
# =============================================================================

variable "name_prefix" {
  description = "Prefixo de nomeação"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "cost_center" {
  description = "Cost center FinOps - sobrescreve o default 'engineering' do módulo upstream"
  type        = string
  default     = "NGO-Core"
}

variable "vpc_id" {
  description = "ID da VPC onde a instância será criada"
  type        = string
}

variable "subnet_id" {
  description = "Subnet PÚBLICA onde o bastion será lançado (precisa de IP público p/ SSH)"
  type        = string
}

variable "instance_role" {
  description = <<-EOT
    Nome do IAM Instance Profile a anexar à EC2. Padrão: null (SEM profile).
    Recomendado deixar null: o bootstrap autentica no EKS pelas CREDENCIAIS
    ESTÁTICAS da sessão (escritas em ~/.aws/credentials via user_data) — a MESMA
    identidade que criou o cluster e que tem admin (bootstrap_cluster_creator_
    admin_permissions). Um instance profile (ex.: LabInstanceProfile → LabRole)
    pode resolver como um principal diferente SEM admin no cluster, impedindo
    instalar ingress-nginx/external-secrets/ArgoCD/etc.
  EOT
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# Configuração da Instância
# -----------------------------------------------------------------------------
# NOTA: a AMI é resolvida por data source (Amazon Linux 2023 amd64) no main.tf.
# amd64 é obrigatório: o bootstrap baixa binários linux/amd64 (kubectl/helm).
# AL2023 já traz a AWS CLI v2 pré-instalada.
variable "instance_type" {
  description = "Tipo da instância (amd64). t3.micro basta p/ o bootstrap (mesmo tamanho do bootstrap efêmero original)."
  type        = string
  default     = "t3.micro"
}

variable "volume_size" {
  description = "Tamanho do volume root em GB"
  type        = number
  default     = 30
}

variable "associate_public_ip" {
  description = "Associar IP público (o bastion é acessado por SSH externamente)"
  type        = bool
  default     = true
}

variable "create_eip" {
  description = "Criar Elastic IP (IP fixo p/ o allowlist de SSH e o ssh_command)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Acesso SSH (bastion)
# -----------------------------------------------------------------------------
variable "key_name" {
  description = "Nome do EC2 Key Pair para SSH (AWS Academy: 'vockey'). VERIFIQUE que existe na sua conta."
  type        = string
  default     = "vockey"
}

variable "ssh_allowed_cidrs" {
  description = <<-EOT
    CIDRs autorizados a acessar a porta 22 (SSH) do bastion.
    Vazio ([]) = NENHUMA regra de ingress é criada (fail-safe).
    Defina o SEU IP público /32 (ex: ["203.0.113.4/32"]).
  EOT
  type        = list(string)
  default     = []
}

# =============================================================================
# Bootstrap da Plataforma K8s (antes no módulo `platform` → módulo `bootstrap`)
# =============================================================================

# -----------------------------------------------------------------------------
# Cluster alvo (vem do módulo platform)
# -----------------------------------------------------------------------------
variable "region" {
  description = "Região AWS (usada no `aws eks update-kubeconfig` dentro do bastion)"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster EKS a ser bootstrapado"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = <<-EOT
    Security Group do control plane do EKS. É ANEXADO ao bastion (SG secundário)
    para que o kubectl alcance o API server privado — mesmo truque que a EC2 de
    bootstrap efêmera (REMOVIDA) usava.
  EOT
  type        = string
}

# -----------------------------------------------------------------------------
# Credenciais Academy (escritas em ~/.aws/credentials via user_data)
# -----------------------------------------------------------------------------
# Limitação Academy: sem OIDC/IRSA; o Instance Profile pode não ter permissão
# de EKS, então passamos credenciais estáticas (igual ao bootstrap original).
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

# -----------------------------------------------------------------------------
# Versões das ferramentas (defaults = os que o módulo bootstrap usava)
# -----------------------------------------------------------------------------
variable "kubectl_version" {
  description = "Versão do kubectl (binário linux/amd64)"
  type        = string
  default     = "1.32.0"
}

variable "helm_version" {
  description = "Versão do Helm (binário linux/amd64)"
  type        = string
  default     = "3.17.3"
}

variable "argocd_version" {
  description = "Versão do chart Helm do ArgoCD (>=7.7.0 tem bug de rootpath; usar 7.6.12)"
  type        = string
  default     = "7.6.12"
}

variable "argocd_namespace" {
  description = "Namespace do ArgoCD"
  type        = string
  default     = "argocd"
}

variable "external_secrets_version" {
  description = "Versão do chart Helm do External Secrets Operator"
  type        = string
  default     = "0.17.0"
}

variable "metrics_server_version" {
  description = "Versão do Metrics Server (v0.8.0+ tem bug de appProtocol; usar v0.7.2)"
  type        = string
  default     = "v0.7.2"
}

# -----------------------------------------------------------------------------
# Feature flags (o que instalar)
# -----------------------------------------------------------------------------
variable "install_argocd" {
  description = "Instalar ArgoCD via Helm"
  type        = bool
  default     = true
}

variable "install_ingress_nginx" {
  description = "Aplicar ingress-nginx"
  type        = bool
  default     = true
}

variable "install_external_secrets" {
  description = "Instalar External Secrets Operator via Helm"
  type        = bool
  default     = true
}

variable "install_metrics_server" {
  description = "Instalar Metrics Server"
  type        = bool
  default     = true
}

variable "apply_namespaces" {
  description = "Aplicar os namespaces"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Ingress do ArgoCD
# -----------------------------------------------------------------------------
variable "argocd_ingress_enabled" {
  description = "Criar Ingress NGINX para o ArgoCD (requer install_ingress_nginx=true)"
  type        = bool
  default     = true
}

variable "argocd_ingress_host" {
  description = "Host do Ingress do ArgoCD"
  type        = string
  default     = "solidary.local"
}

variable "argocd_ingress_path" {
  description = "Path prefix do Ingress do ArgoCD"
  type        = string
  default     = "/argocd"
}
