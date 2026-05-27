# =============================================================================
# Root Module — SolidaryTech Infrastructure (Fase 5)
# =============================================================================
# Este arquivo orquestra os módulos filhos. Mantém-se DECLARATIVO e LIMPO:
# apenas chamadas `module` com inputs. Toda lógica (loops, condicionais,
# locais) reside dentro dos módulos filhos para garantir encapsulamento e
# reusabilidade.
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Networking — VPC + Security Groups
# -----------------------------------------------------------------------------
module "networking" {
  source = "./modules/networking"

  name_prefix  = local.name_prefix
  environment  = var.environment
  cluster_name = "${local.name_prefix}-eks"
}

# -----------------------------------------------------------------------------
# 2. Registry — ECR (for_each por microsserviço)
# -----------------------------------------------------------------------------
module "registry" {
  source = "./modules/registry"

  environment   = var.environment
  name_prefix   = lower(var.project)
  microservices = local.microservices
}

# -----------------------------------------------------------------------------
# 3. Messaging — SQS (fila principal + DLQ + alarme)
# -----------------------------------------------------------------------------
module "messaging" {
  source = "./modules/messaging"

  name_prefix = local.name_prefix
  environment = var.environment
  cost_center = var.cost_center
}

# -----------------------------------------------------------------------------
# 4. Databases — RDS (for_each: ngo + donation) + DynamoDB (volunteers)
# -----------------------------------------------------------------------------
module "databases" {
  source = "./modules/databases"

  name_prefix        = local.name_prefix
  environment        = var.environment
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  allowed_sg_id      = module.networking.eks_workers_sg_id
  rds_databases      = local.rds_databases
}

# -----------------------------------------------------------------------------
# 5. VPN — Pritunl EC2 (acesso ao EKS privado)
# -----------------------------------------------------------------------------
module "vpn" {
  source = "./modules/vpn"

  name_prefix = local.name_prefix
  environment = var.environment
  cost_center = var.cost_center
  vpc_id      = module.networking.vpc_id
  subnet_id   = module.networking.public_subnet_ids[0]
  # AWS Academy: LabInstanceProfile é o ÚNICO instance profile disponível.
  # NOTA: instance_role espera um Instance Profile *name*, não o Role name.
  # No Academy, ambos são pré-criados, mas têm nomes diferentes:
  #   - Role: "LabRole"
  #   - Instance Profile: "LabInstanceProfile"  ← esse que vai aqui
  instance_role = "LabInstanceProfile"
}

# -----------------------------------------------------------------------------
# 6. Platform — EKS Cluster + Bootstrap (manifestos via EC2 efêmera)
# -----------------------------------------------------------------------------
# Bootstrap aplica os manifestos K8s a partir de uma EC2 DENTRO da VPC.
# É necessário porque o cluster EKS é privado e o runner do GitHub Actions
# não conseguiria atingir o API server diretamente.
# -----------------------------------------------------------------------------
module "platform" {
  source = "./modules/platform"

  name_prefix        = local.name_prefix
  environment        = var.environment
  cluster_name       = "${local.name_prefix}-eks"
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  workers_sg_id      = module.networking.eks_workers_sg_id
  vpn_sg_id          = module.vpn.security_group_id

  # IAM (AWS Academy: reusa LabRole para tudo)
  cluster_role_arn = data.aws_iam_role.lab_role.arn
  node_role_arn    = data.aws_iam_role.lab_role.arn

  # Credenciais Academy (passadas ao bootstrap EC2 — limitação Academy)
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_session_token     = var.aws_session_token
}
