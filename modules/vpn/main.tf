# =============================================================================
# VPN — Pritunl em EC2
# =============================================================================
# AWS Academy Limitation: usamos `LabInstanceProfile` pré-existente.
# Em produção, criaríamos um Instance Profile dedicado com permissões mínimas.
# =============================================================================

# -----------------------------------------------------------------------------
# Renderiza o user_data com as tags de imagem injetadas (sem 'latest')
# -----------------------------------------------------------------------------
locals {
  user_data_rendered = templatefile("${path.module}/user_data.sh", {
    mongo_image_tag   = var.mongo_image_tag
    pritunl_image_tag = var.pritunl_image_tag
  })
}

module "pritunl_vpn" {
  # checkov:skip=CKV2_AWS_5:Security Group is attached internally by module
  # checkov:skip=CKV_AWS_88:VPN appliance requires public IP for client connections (intentional)
  # checkov:skip=CKV2_AWS_19:EIP attached to VPN EC2 (false positive - Checkov doesn't detect via module)
  source = "github.com/brianmonteiro54/terraform-aws-ec2//modules/ec2?ref=17c9a7d61d695ae4fa4033e091c2744377e583ac"

  # --- Identificação ---
  instance_name = "${var.name_prefix}-vpn"
  environment   = var.environment
  cost_center   = var.cost_center

  # --- Configuração da Instância ---
  ami_id               = var.ami_id
  instance_type        = var.instance_type
  iam_instance_profile = var.instance_role
  user_data            = local.user_data_rendered

  # --- Rede ---
  vpc_id                      = var.vpc_id
  subnet_id                   = var.subnet_id
  associate_public_ip_address = var.associate_public_ip

  # --- Elastic IP ---
  create_eip = var.create_eip

  # --- Storage ---
  root_volume_size      = var.volume_size
  root_volume_type      = "gp3"
  enable_ebs_encryption = true
  create_kms_key        = false

  # --- Security Group (criado pelo módulo, regras explícitas) ---
  create_security_group = true
  security_group_ingress_rules = [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Pritunl admin web (HTTPS)"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Pritunl admin web (HTTP redirect)"
    },
    {
      from_port   = 5050
      to_port     = 5060
      protocol    = "udp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Pritunl VPN client tunnel (UDP range)"
    },
  ]

  # --- Monitoramento ---
  enable_cloudwatch_alarms = true
  enable_auto_recovery     = true
}
