# =============================================================================
# Bastion — Locals
# =============================================================================
# 1. Renderiza o user_data do bootstrap K8s
# 2. Carrega/gera os manifestos K8s (movidos do antigo módulo platform)
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Manifestos K8s a partir de arquivos
  # ---------------------------------------------------------------------------
  namespaces_yaml         = file("${path.module}/kubernetes/namespaces.yaml")
  ingress_nginx_yaml      = file("${path.module}/kubernetes/ingress-nginx.yaml")
  ingress_nginx_lb_yaml   = file("${path.module}/kubernetes/ingress-nginx-lb.yaml")
  external_secrets_values = file("${path.module}/kubernetes/external-secrets-values.yaml")

  # ---------------------------------------------------------------------------
  # Credenciais AWS escritas em ~/.aws/credentials na EC2
  # ---------------------------------------------------------------------------
  aws_credentials = <<-EOT
    [default]
    aws_access_key_id=${var.aws_access_key_id}
    aws_secret_access_key=${var.aws_secret_access_key}
    aws_session_token=${var.aws_session_token}
  EOT

  # ---------------------------------------------------------------------------
  # Secret aws-credentials em cada namespace
  # ---------------------------------------------------------------------------
  # AWS Academy: aplicações precisam de credenciais via Secret porque não
  # há OIDC/IRSA disponível. Em produção real, isso seria IRSA com
  # ServiceAccount.
  # ---------------------------------------------------------------------------
  aws_credentials_targets = {
    "solidarytech-ngo" = {
      "app.kubernetes.io/name"      = "ngo-service"
      "app.kubernetes.io/component" = "ngo"
      "app.kubernetes.io/part-of"   = "solidarytech"
    }
    "solidarytech-donation" = {
      "app.kubernetes.io/name"      = "donation-service"
      "app.kubernetes.io/component" = "donation"
      "app.kubernetes.io/part-of"   = "solidarytech"
    }
    "solidarytech-volunteer" = {
      "app.kubernetes.io/name"      = "volunteer-service"
      "app.kubernetes.io/component" = "volunteer"
      "app.kubernetes.io/part-of"   = "solidarytech"
    }
    "monitoring" = {
      "app.kubernetes.io/component" = "observability"
      "app.kubernetes.io/part-of"   = "solidarytech"
    }
  }

  # Base64 calculado UMA vez (DRY)
  _aws_access_key_b64    = base64encode(var.aws_access_key_id)
  _aws_secret_key_b64    = base64encode(var.aws_secret_access_key)
  _aws_session_token_b64 = base64encode(var.aws_session_token)

  aws_credentials_secrets_yaml = join("\n---\n", [
    for ns, labels in local.aws_credentials_targets : <<-EOT
      apiVersion: v1
      kind: Secret
      metadata:
        name: aws-credentials
        namespace: ${ns}
        labels:
      ${join("\n", [for k, v in labels : "    ${k}: ${v}"])}
      type: Opaque
      data:
        access-key: ${local._aws_access_key_b64}
        secret-access-key: ${local._aws_secret_key_b64}
        session-token: ${local._aws_session_token_b64}
    EOT
  ])

  # ---------------------------------------------------------------------------
  # ArgoCD Root Application (App-of-Apps)
  # ---------------------------------------------------------------------------
  argocd_root_app_yaml = <<-EOT
    apiVersion: argoproj.io/v1alpha1
    kind: Application
    metadata:
      name: solidarytech-root
      namespace: argocd
      labels:
        app.kubernetes.io/part-of: solidarytech
        app.kubernetes.io/component: root
      finalizers:
        - resources-finalizer.argocd.argoproj.io
    spec:
      project: default
      source:
        repoURL: https://github.com/brianmonteiro54/solidarytech-monitoring-gitops.git
        targetRevision: main
        path: apps
        directory:
          recurse: false
          include: "*.yaml"
      destination:
        server: https://kubernetes.default.svc
        namespace: argocd
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
          - CreateNamespace=true
  EOT

  # ---------------------------------------------------------------------------
  # Manifestos adicionais (aplicados DEPOIS dos CRDs do ArgoCD)
  # ---------------------------------------------------------------------------
  additional_manifests = {
    "01-aws-credentials-secrets" = local.aws_credentials_secrets_yaml
    "02-argocd-root-app"         = local.argocd_root_app_yaml
  }

  # ---------------------------------------------------------------------------
  # user_data do bootstrap K8s (base AL2023, persistente)
  # ---------------------------------------------------------------------------
  user_data_rendered = templatefile("${path.module}/user_data.sh", {
    # --- Cluster / região ---
    cluster_name = var.cluster_name
    region       = var.region

    # --- Versões ---
    kubectl_version          = var.kubectl_version
    helm_version             = var.helm_version
    argocd_namespace         = var.argocd_namespace
    argocd_version           = var.argocd_version
    external_secrets_version = var.external_secrets_version
    metrics_server_version   = var.metrics_server_version

    # --- Manifestos ---
    namespaces_yaml         = local.namespaces_yaml
    ingress_nginx_yaml      = local.ingress_nginx_yaml
    ingress_nginx_acm_yaml  = local.ingress_nginx_lb_yaml
    external_secrets_values = local.external_secrets_values
    additional_manifests    = local.additional_manifests

    # --- Feature flags ---
    install_argocd           = var.install_argocd
    install_ingress_nginx    = var.install_ingress_nginx
    install_external_secrets = var.install_external_secrets
    install_metrics_server   = var.install_metrics_server
    apply_namespaces         = var.apply_namespaces

    # --- Ingress ArgoCD ---
    argocd_ingress_enabled = var.argocd_ingress_enabled
    argocd_ingress_host    = var.argocd_ingress_host
    argocd_ingress_path    = var.argocd_ingress_path

    # --- Credenciais ---
    aws_credentials = local.aws_credentials

    # --- Extra (não usado por padrão) ---
    extra_commands = ""
  })

  # ---------------------------------------------------------------------------
  # Regras de ingress do SG do bastion
  # ---------------------------------------------------------------------------
  # Só SSH — e só se ssh_allowed_cidrs for informado (fail-safe: lista vazia =
  # nenhuma regra de ingress). O egress (default allow-all do módulo EC2) é o
  # que o bastion usa para alcançar o API do EKS e baixar binários.
  #
  # Normalização: se o usuário informar um IP sem máscara (ex: "1.2.3.4"),
  # adicionamos "/32" automaticamente (CIDR exige prefixo). Valores que já têm
  # "/" passam intactos (ex: "10.0.0.0/16").
  ssh_cidrs_normalized = [
    for c in var.ssh_allowed_cidrs : can(regex("/", c)) ? c : "${c}/32"
  ]

  ingress_rules = length(local.ssh_cidrs_normalized) > 0 ? [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = local.ssh_cidrs_normalized
      description = "SSH admin (bastion) - CIDRs restritos"
    }
  ] : []
}
