# =============================================================================
# Bastion — EC2 única: SSH jump host + Bootstrap K8s
# =============================================================================
# Consolida o antigo módulo `bootstrap` (EC2 efêmera) numa ÚNICA instância
# persistente que:
#   - serve de bastion host (SSH) para alcançar o EKS/RDS privados;
#   - aplica os manifestos K8s no EKS privado via user_data (uma vez, no boot).
#
# Sem VPN/Pritunl. Como alcança o API server privado: o SG do control plane do
# EKS é anexado como SG secundário (var.eks_cluster_security_group_id) — mesmo
# mecanismo que a antiga EC2 de bootstrap efêmera (REMOVIDA) usava.
#
# AWS Academy: SEM IAM Instance Profile. A EC2 autentica no EKS pelas credenciais
# estáticas da sessão (~/.aws/credentials via user_data) = identidade criadora do
# cluster (admin). Ver a variável instance_role para o porquê.
# =============================================================================

# -----------------------------------------------------------------------------
# Data Sources
# -----------------------------------------------------------------------------
# AMI Amazon Linux 2023 amd64 (mesma base do bootstrap efêmero original).
# amd64 é obrigatório (o bootstrap baixa binários linux/amd64). AL2023 já traz
# a AWS CLI v2 pré-instalada — que o `aws eks update-kubeconfig` usa.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# -----------------------------------------------------------------------------
# EC2 (módulo Git versionado por hash imutável)
# -----------------------------------------------------------------------------
module "bastion" {
  # checkov:skip=CKV2_AWS_5:Security Group is attached internally by module
  # checkov:skip=CKV_AWS_88:Bastion requires public IP for SSH access (intentional)
  # checkov:skip=CKV2_AWS_19:EIP attached to bastion EC2 (false positive - Checkov doesn't detect via module)
  source = "github.com/brianmonteiro54/terraform-aws-ec2//modules/ec2?ref=17c9a7d61d695ae4fa4033e091c2744377e583ac"

  # --- Identificação ---
  instance_name = "${var.name_prefix}-bastion"
  environment   = var.environment
  cost_center   = var.cost_center

  # --- Configuração da Instância ---
  ami_id               = data.aws_ami.al2023.id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_role # null por padrão = SEM profile (auth via creds estáticas)
  key_name             = var.key_name

  # user_data via base64+gzip: os manifestos embutidos (ingress-nginx tem ~17KB)
  # estouram o limite de 16KB do user_data em texto puro.
  user_data_base64 = base64gzip(local.user_data_rendered)

  # --- Rede ---
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip

  # SG secundário: o SG do control plane do EKS, para o kubectl alcançar o
  # API server privado (o SG do cluster tem auto-referência que libera 443).
  vpc_security_group_ids = [var.eks_cluster_security_group_id]

  # --- Elastic IP ---
  create_eip = var.create_eip

  # --- Storage ---
  root_volume_size      = var.volume_size
  root_volume_type      = "gp3"
  enable_ebs_encryption = true
  create_kms_key        = false

  # --- Security Group próprio (só SSH, condicional a ssh_allowed_cidrs) ---
  create_security_group        = true
  security_group_ingress_rules = local.ingress_rules

  # --- Monitoramento ---
  enable_cloudwatch_alarms = true
  enable_auto_recovery     = true
}
