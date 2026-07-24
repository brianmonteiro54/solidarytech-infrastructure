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

  # NAT Gateway — FinOps: dev usa single_nat=true, prod usa false (HA)
  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway
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

  # Deletion protection (dev: false, prod: true)
  rds_deletion_protection = var.rds_deletion_protection
}

# -----------------------------------------------------------------------------
# 5. Bastion — EC2 ÚNICA: SSH jump host + Bootstrap K8s
# -----------------------------------------------------------------------------
# Substitui o antigo módulo `bootstrap` (EC2 efêmera) por uma EC2 PERSISTENTE
# que serve de bastion (SSH) para alcançar o EKS/RDS privados e aplica os
# manifestos no EKS via user_data (uma vez, no primeiro boot). Sem VPN/Pritunl.
#
# Inversão de dependência: o bastion DEPENDE do platform (o bootstrap precisa
# do cluster EKS já existindo). O platform NÃO depende mais do bastion — a
# antiga var `vpn_sg_id` era morta (declarada mas nunca usada), então removê-la
# quebrou o ciclo sem perda funcional. O bastion alcança o API server privado
# anexando o SG do control plane (eks_cluster_security_group_id) como SG
# secundário — a mesma técnica que a antiga EC2 de bootstrap efêmera (REMOVIDA) usava.
# -----------------------------------------------------------------------------
module "bastion" {
  source = "./modules/bastion"

  name_prefix = local.name_prefix
  environment = var.environment
  cost_center = var.cost_center
  vpc_id      = module.networking.vpc_id
  subnet_id   = module.networking.public_subnet_ids[0]

  # SEM IAM Instance Profile de propósito (instance_role fica null). O bootstrap
  # autentica no EKS usando as credenciais estáticas da sessão (escritas em
  # ~/.aws/credentials via user_data) — a MESMA identidade que criou o cluster e
  # que tem admin. Anexar LabInstanceProfile/LabRole poderia resolver como outro
  # principal sem admin no cluster, impedindo instalar ingress/external-secrets/etc.

  # SSH (bastion): defina seu IP /32 em envs/<env>/terraform.tfvars
  ssh_allowed_cidrs = var.ssh_allowed_cidrs

  # --- Bootstrap: cluster alvo (vem do platform) ---
  region                        = var.region
  cluster_name                  = module.platform.cluster_name
  eks_cluster_security_group_id = module.platform.cluster_security_group_id

  # --- Credenciais Academy (escritas em ~/.aws/credentials via user_data) ---
  aws_access_key_id     = var.aws_access_key_id
  aws_secret_access_key = var.aws_secret_access_key
  aws_session_token     = var.aws_session_token

  # O bootstrap exige o cluster (e node groups) prontos antes de rodar.
  depends_on = [module.platform]
}

# -----------------------------------------------------------------------------
# 6. Platform — EKS Cluster (control plane, addons, node groups)
# -----------------------------------------------------------------------------
# O bootstrap dos manifestos K8s foi movido para o módulo `bastion` (acima),
# que agora aplica tudo via user_data numa EC2 dentro da VPC (o API server é
# privado e o runner do GitHub Actions não o alcança de fora).
# -----------------------------------------------------------------------------
module "platform" {
  source = "./modules/platform"

  name_prefix        = local.name_prefix
  cluster_name       = "${local.name_prefix}-eks"
  private_subnet_ids = module.networking.private_subnet_ids
  workers_sg_id      = module.networking.eks_workers_sg_id

  # Deletion protection (dev: false, prod: true)
  cluster_deletion_protection = var.cluster_deletion_protection

  # Retenção dos logs do control plane no CloudWatch (dev: curta, prod: estendida)
  cluster_log_retention_in_days = var.cluster_log_retention_in_days

  # IAM (AWS Academy: reusa LabRole para tudo)
  cluster_role_arn = data.aws_iam_role.lab_role.arn
  node_role_arn    = data.aws_iam_role.lab_role.arn
}

# -----------------------------------------------------------------------------
# 7. Secrets — AWS Secrets Manager (consumido pelo External Secrets no cluster)
# -----------------------------------------------------------------------------
module "secrets" {
  source = "./modules/secrets"

  grafana_admin_user     = var.grafana_admin_user
  grafana_admin_password = var.grafana_admin_password
  GITHUB_TOKEN           = var.token_github
  discord_webhook_url    = var.discord_webhook_url
  pagerduty_service_key  = var.pagerduty_service_key
  new_relic_api_key      = var.new_relic_api_key
  anthropic_api_key      = var.anthropic_api_key

  donation_db_endpoint = module.databases.rds_endpoints["donation"]
  donation_db_name     = module.databases.rds_db_names["donation"]
  donation_sqs_url     = module.messaging.queue_url
  ngo_db_endpoint      = module.databases.rds_endpoints["ngo"]
  ngo_db_name          = module.databases.rds_db_names["ngo"]
}
