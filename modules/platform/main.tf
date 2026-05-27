# =============================================================================
# Platform — EKS Cluster + Bootstrap
# =============================================================================
# EKS:        cria o control plane, addons e node groups
# Bootstrap:  EC2 efêmera DENTRO da VPC aplica manifestos via kubectl/helm
#             (necessário porque o API server é PRIVADO)
# =============================================================================

# -----------------------------------------------------------------------------
# 1. EKS Cluster (módulo Git versionado)
# -----------------------------------------------------------------------------
module "eks" {
  # checkov:skip=CKV_AWS_38:Public access desabilitado via endpoint_public_access
  # checkov:skip=CKV_AWS_37:Todos os tipos de log estão habilitados
  source = "github.com/brianmonteiro54/terraform-aws-eks-platform//modules/eks?ref=116e4fa01cd755dbe0516249c6d916b52274ba6b"

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
  cluster_logging_enabled   = true
  enabled_cluster_log_types = var.enabled_cluster_log_types

  # --- Acesso e Permissões ---
  authentication_mode                         = "API_AND_CONFIG_MAP"
  bootstrap_cluster_creator_admin_permissions = true
  support_type                                = "STANDARD"
  deletion_protection                         = false

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
  }

  launch_template_worker_tag         = "${var.name_prefix}-eks-worker"
  launch_template_tag_resource_types = ["instance", "volume"]

  # --- Node Groups ---
  nodegroups                = var.nodegroups
  nodegroup_max_unavailable = 1

  # --- Addons (vpc-cni, coredns, kube-proxy) ---
  addons = var.addons

  # --- Tags ---
  cluster_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

# -----------------------------------------------------------------------------
# 2. Bootstrap — aplica manifestos K8s via EC2 efêmera
# -----------------------------------------------------------------------------
# Necessário porque o API server EKS é privado (endpoint_public_access=false)
# e o GitHub Actions runner não consegue alcançá-lo de fora da VPC.
# A EC2 é destruída automaticamente após terminar o bootstrap.
# -----------------------------------------------------------------------------
module "bootstrap" {
  # checkov:skip=CKV2_AWS_41:Credenciais temporárias Academy via user_data (limitação documentada)
  source = "github.com/brianmonteiro54/terraform-aws-eks-bootstrap//modules/bootstrap?ref=6025316263570e7f9dd5b09439615c4848984a49"

  # --- Cluster ---
  cluster_name                  = module.eks.cluster_name
  vpc_id                        = var.vpc_id
  subnet_id                     = var.private_subnet_ids[0]
  eks_cluster_security_group_id = module.eks.cluster_security_group_id
  iam_instance_profile          = "LabInstanceProfile"

  # --- Credenciais Academy (passadas via user_data, limitação documentada) ---
  aws_credentials = <<-EOT
    [default]
    aws_access_key_id=${var.aws_access_key_id}
    aws_secret_access_key=${var.aws_secret_access_key}
    aws_session_token=${var.aws_session_token}
  EOT

  # --- Manifestos de Plataforma ---
  namespaces_yaml         = local.namespaces_yaml
  ingress_nginx_yaml      = local.ingress_nginx_yaml
  ingress_nginx_acm_yaml  = local.ingress_nginx_lb_yaml
  external_secrets_values = local.external_secrets_values

  # --- Feature Flags ---
  install_argocd           = true
  install_ingress_nginx    = true
  install_external_secrets = true
  install_metrics_server   = true
  apply_namespaces         = true

  # --- ArgoCD Ingress (subdomínio /argocd) ---
  argocd_ingress_enabled = true
  argocd_ingress_host    = "solidary.local"
  argocd_ingress_path    = "/argocd"

  # --- Manifestos adicionais (aplicados DEPOIS dos CRDs do ArgoCD) ---
  additional_manifests = {
    "01-aws-credentials-secrets" = local.aws_credentials_secrets_yaml
    "02-argocd-root-app"         = local.argocd_root_app_yaml
  }

  tags = {
    Component = "platform-bootstrap"
  }

  depends_on = [module.eks]
}
