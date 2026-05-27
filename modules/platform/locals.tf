# =============================================================================
# Platform — Locals (manifestos K8s adicionais)
# =============================================================================
# Manifestos que dependem de valores Terraform dinâmicos (credenciais, ARNs).
# São aplicados PELO bootstrap APÓS os CRDs do ArgoCD ficarem prontos.
# =============================================================================

locals {
  # ---------------------------------------------------------------------------
  # Carregar manifestos K8s de arquivos
  # ---------------------------------------------------------------------------
  namespaces_yaml         = file("${path.module}/kubernetes/namespaces.yaml")
  ingress_nginx_yaml      = file("${path.module}/kubernetes/ingress-nginx.yaml")
  ingress_nginx_lb_yaml   = file("${path.module}/kubernetes/ingress-nginx-lb.yaml")
  external_secrets_values = file("${path.module}/kubernetes/external-secrets-values.yaml")

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
  # Aponta para o repositório de GitOps que vai conter os manifestos
  # das aplicações (a ser criado em uma próxima etapa).
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
        repoURL: https://github.com/brianmonteiro54/solidarytech-gitops.git
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
}
