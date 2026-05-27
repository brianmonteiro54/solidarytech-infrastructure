# =============================================================================
# VPN Module — Variables
# =============================================================================
# Pritunl VPN em EC2 para acesso seguro ao EKS privado.
# =============================================================================

variable "name_prefix" {
  description = "Prefixo de nomeação"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "ID da VPC onde a instância será criada"
  type        = string
}

variable "subnet_id" {
  description = "Subnet pública onde a EC2 será lançada"
  type        = string
}

variable "instance_role" {
  description = "Nome do IAM Instance Profile (AWS Academy: LabInstanceProfile)"
  type        = string
  default     = "LabInstanceProfile"
}

# -----------------------------------------------------------------------------
# Configuração da Instância
# -----------------------------------------------------------------------------
variable "ami_id" {
  description = "AMI do Ubuntu 22.04 LTS (us-east-1)"
  type        = string
  default     = "ami-096ea6a12ea24a797"
}

variable "instance_type" {
  description = "Tipo da instância (t4g.micro é ARM e mais barato)"
  type        = string
  default     = "t4g.micro"
}

variable "volume_size" {
  description = "Tamanho do volume root em GB"
  type        = number
  default     = 8
}

variable "associate_public_ip" {
  description = "Associar IP público (necessário para VPN acessível externamente)"
  type        = bool
  default     = true
}

variable "create_eip" {
  description = "Criar Elastic IP (recomendado para VPN - IP fixo entre reboots)"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# Versionamento de Imagens Docker (sem `latest` — feedback do avaliador!)
# -----------------------------------------------------------------------------
variable "mongo_image_tag" {
  description = "Tag do MongoDB (sem 'latest' — pinning explícito)"
  type        = string
  default     = "7.0.14" # LTS estável (out/2024)
}

variable "pritunl_image_tag" {
  description = "Tag da imagem Pritunl (sem 'latest')"
  type        = string
  default     = "1.32.4805.95-3" # Última estável do goofball222/pritunl
}
