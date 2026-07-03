# =============================================================================
# Platform — EKS Cluster
# =============================================================================
# Cria o control plane, addons e node groups do EKS.
# O bootstrap dos manifestos K8s NÃO fica mais aqui — foi movido para o módulo
# `bastion`, que aplica tudo via user_data. (Antes havia uma EC2 efêmera de
# bootstrap neste módulo; ela foi REMOVIDA.)
# =============================================================================

# -----------------------------------------------------------------------------
# 0. CloudWatch Log Group do control plane (RETENÇÃO EXPLÍCITA)
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "eks" {
  # checkov:skip=CKV_AWS_158:CMK não viável na conta AWS Academy (sem KMS, igual enable_secrets_encryption=false)
  # checkov:skip=CKV_AWS_338:Retenção definida por ambiente via var.cluster_log_retention_in_days (FinOps: dev curto, prod estendido)
  name              = "/aws/eks/${var.cluster_name}/cluster"
  retention_in_days = var.cluster_log_retention_in_days

  tags = {
    Name      = "/aws/eks/${var.cluster_name}/cluster"
    Component = "eks-control-plane-logs"
  }
}

# -----------------------------------------------------------------------------
# 1. EKS Cluster (módulo Git versionado)
# -----------------------------------------------------------------------------
module "eks" {
  # checkov:skip=CKV_AWS_38:Public access desabilitado via endpoint_public_access
  # checkov:skip=CKV_AWS_37:Todos os tipos de log estão habilitados
  source = "github.com/brianmonteiro54/terraform-aws-eks-platform//modules/eks?ref=2583f0cc17f16d4e253c8b500d495828126521c0"

  # --- Controle de Módulo (AWS Academy: reusa LabRole, não cria nada IAM) ---
  create_cluster         = true
  create_iam_roles       = false
  create_launch_template = true
  create_node_groups     = true

  cluster_role_arn = var.cluster_role_arn
  node_role_arn    = var.node_role_arn

  # --- Configurações Gerais ---
  cluster_name              = var.cluster_name
  cluster_version           = var.cluster_version
  enable_secrets_encryption = false # Academy não permite criar KMS
  create_kms_key            = false

  # --- Networking ---
  cluster_subnet_ids         = var.private_subnet_ids
  nodegroup_subnet_ids       = var.private_subnet_ids
  cluster_security_group_ids = [var.workers_sg_id]
  worker_security_group_ids  = [var.workers_sg_id]

  endpoint_private_access = var.endpoint_private_access
  endpoint_public_access  = var.endpoint_public_access
  service_ipv4_cidr       = "172.20.0.0/16"
  ip_family               = "ipv4"

  # --- Logs (observability) ---
  # Escreve no log group aws_cloudwatch_log_group.eks (retenção controlada).
  cluster_logging_enabled   = true
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # --- Acesso e Permissões ---
  authentication_mode                         = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
  support_type                                = "STANDARD"
  deletion_protection                         = var.cluster_deletion_protection

  # --- Launch Template ---
  launch_template_name                   = "${var.name_prefix}-eks-lt"
  launch_template_instance_type          = var.launch_template_instance_type
  launch_template_update_default_version = true
  launch_template_volume_size            = var.launch_template_volume_size
  launch_template_volume_type            = "gp3"
  launch_template_volume_iops            = 3000
  launch_template_device_name            = "/dev/xvda"
  launch_template_delete_on_termination  = true
  launch_template_encrypted              = true
  launch_template_ebs_optimized          = true

  launch_template_metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 obrigatório (segurança)
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled" # Permite acessar tags via metadata service
  }

  launch_template_worker_tag         = "${var.name_prefix}-eks-worker"
  launch_template_tag_resource_types = ["instance", "volume"]

  # --- Node Groups
  nodegroups                = var.nodegroups
  nodegroup_az_mapping      = var.nodegroup_az_mapping
  nodegroup_max_unavailable = 1

  # --- Addons (vpc-cni, coredns, kube-proxy) ---
  addons = var.addons

  # --- Tags ---
  cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
  depends_on = [aws_cloudwatch_log_group.eks]
}

