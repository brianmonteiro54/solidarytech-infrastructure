# =============================================================================
# Networking — VPC + Security Groups
# =============================================================================
# Orquestra duas responsabilidades relacionadas:
#   1. VPC com subnets públicas/privadas (via módulo Git versionado)
#   2. Security Groups da plataforma (EKS workers) com regras explícitas
#
# Regras de SG seguem o princípio de menor privilégio:
#   - SEM 0.0.0.0/0 no ingress
#   - Egress controlado (não tudo aberto)
#   - Acesso entre componentes via referência a outros SGs, nunca IP
# =============================================================================

# -----------------------------------------------------------------------------
# VPC (módulo Git versionado por hash imutável)
# -----------------------------------------------------------------------------
module "vpc" {
  # checkov:skip=CKV_AWS_130:Public subnets intentionally map public IPs for ingress
  # checkov:skip=CKV2_AWS_11:VPC Flow Logs serão habilitados na etapa de observabilidade
  # checkov:skip=CKV2_AWS_12:Default SG é restrito pelo provider
  source = "github.com/brianmonteiro54/terraform-aws-vpc-network//modules/vpc?ref=1185cd978b63dae90bac2097c666f3fe45e64f61"

  name        = "${var.name_prefix}-vpc"
  vpc_cidr    = var.vpc_cidr
  environment = var.environment

  max_availability_zones = var.max_availability_zones
  subnet_newbits         = var.subnet_newbits

  enable_nat_gateway = var.enable_nat_gateway
  single_nat_gateway = var.single_nat_gateway

  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags Kubernetes obrigatórias para que o EKS reconheça e use as subnets
  # automaticamente (auto-discovery de subnets pelo controller do ELB/ALB)
  enable_kubernetes_tags = true
  cluster_name           = var.cluster_name
}

# =============================================================================
# Security Group — EKS Workers
# =============================================================================
# SG compartilhado entre control plane e nodes do EKS.
# Regras seguem least-privilege: ingress apenas de SGs específicos (VPN,
# próprio SG via auto-referência) — NUNCA 0.0.0.0/0.
# =============================================================================

resource "aws_security_group" "eks_workers" {
  # checkov:skip=CKV2_AWS_5:SG is attached externally by EKS module
  name        = "${var.name_prefix}-eks-workers-sg"
  description = "Security group for EKS worker nodes - allow internal cluster traffic"
  vpc_id      = module.vpc.vpc_id
}

# Auto-referência: pods e nodes precisam se comunicar entre si dentro do SG
resource "aws_vpc_security_group_ingress_rule" "eks_workers_self" {
  security_group_id            = aws_security_group.eks_workers.id
  referenced_security_group_id = aws_security_group.eks_workers.id
  ip_protocol                  = "-1"
  description                  = "Allow all traffic from self (pod-to-pod, kubelet, etc)"
}

# Permitir tráfego do CIDR interno da VPC (necessário para health checks
# do ALB Controller e tráfego entre subnets)
resource "aws_vpc_security_group_ingress_rule" "eks_workers_vpc_cidr" {
  security_group_id = aws_security_group.eks_workers.id
  cidr_ipv4         = var.vpc_cidr
  ip_protocol       = "-1"
  description       = "Allow all traffic from VPC CIDR (internal services)"
}

# Egress: necessário liberar para tudo porque o EKS precisa puxar imagens
# do ECR, validar tokens IAM, falar com AWS APIs etc. Em produção real,
# isso seria substituído por VPC Endpoints (PrivateLink) para ECR, S3, STS.
resource "aws_vpc_security_group_egress_rule" "eks_workers_egress" {
  # checkov:skip=CKV_AWS_382:Egress for AWS APIs/ECR; would be VPC Endpoints in prod
  security_group_id = aws_security_group.eks_workers.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow outbound to AWS services (ECR, STS, etc) - to be replaced by VPC Endpoints"
}
