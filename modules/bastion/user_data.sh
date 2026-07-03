#!/bin/bash
# =============================================================================
# Bastion Bootstrap Script — EKS (EC2 persistente)
# =============================================================================
# É o script de bootstrap do EKS rodando num BASTION persistente. Idêntico ao
# bootstrap efêmero original, EXCETO: não se auto-termina (removidos o
# `sleep 180` e o `shutdown -h now`). A instância permanece viva como bastion
# (SSH jump host) para alcançar o cluster/RDS privados.
# Base: Amazon Linux 2023 (traz AWS CLI v2 pré-instalada).
# Roda UMA vez no primeiro boot (cloud-init). Para re-executar, use
# user_data_replace_on_change + taint, ou rode os passos via SSH.
# =============================================================================
set -uo pipefail

# ── Variáveis (Terraform templatefile) ───────────────────────────────────────
CLUSTER_NAME="${cluster_name}"
REGION="${region}"
export HOME=/root
export KUBECONFIG=/root/.kube/config
KUBECTL_VERSION="${kubectl_version}"
HELM_VERSION="${helm_version}"
ARGOCD_NAMESPACE="${argocd_namespace}"
ARGOCD_VERSION="${argocd_version}"
EXTERNAL_SECRETS_VERSION="${external_secrets_version}"

# ── Logging ──────────────────────────────────────────────────────────────────
LOG_FILE="/var/log/eks-bootstrap.log"
exec > >(tee -a "$LOG_FILE") 2>&1

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"; }

# ── Tracking de resultados ───────────────────────────────────────────────────
declare -a STEP_NAMES=()
declare -a STEP_RESULTS=()
declare -a STEP_TYPES=()
ABORTED=false
ABORT_REASON=""

record() {
  STEP_NAMES+=("$1")
  STEP_RESULTS+=("$2")  # OK | FAIL | SKIP | ABORTED
  STEP_TYPES+=("$3")    # CRITICAL | NORMAL
}

# ── Retry com backoff ────────────────────────────────────────────────────────
retry() {
  local max_attempts=$1
  local delay=$2
  local description=$3
  shift 3

  for attempt in $(seq 1 "$max_attempts"); do
    log "  [$attempt/$max_attempts] $description"
    if "$@"; then
      return 0
    fi
    if [[ $attempt -lt $max_attempts ]]; then
      local wait_time=$((delay * attempt))
      log "  ⏳ Falhou. Retry em $${wait_time}s..."
      sleep "$wait_time"
    fi
  done
  return 1
}

# ── Cleanup: SEMPRE roda, mostra relatório, e termina a instância ────────────
cleanup() {
  echo ""
  log "══════════════════════════════════════════════════"
  log "  📋 RELATÓRIO DO BOOTSTRAP"
  log "══════════════════════════════════════════════════"

  local passed=0 failed=0 skipped=0 aborted=0

  for i in "$${!STEP_NAMES[@]}"; do
    local name="$${STEP_NAMES[$i]}"
    local result="$${STEP_RESULTS[$i]}"
    local type="$${STEP_TYPES[$i]}"

    case "$result" in
      OK)      icon="✅"; ((passed++))  ;;
      FAIL)    icon="❌"; ((failed++))  ;;
      SKIP)    icon="⏭️ "; ((skipped++)) ;;
      ABORTED) icon="🚫"; ((aborted++)) ;;
    esac

    local type_label=""
    [[ "$type" == "CRITICAL" ]] && type_label=" [CRÍTICO]"

    log "  $icon $name$type_label — $result"
  done

  local total=$((passed + failed + skipped + aborted))
  echo ""
  log "  Total: $total | ✅ $passed | ❌ $failed | ⏭️  $skipped | 🚫 $aborted"

  if [[ "$ABORTED" == "true" ]]; then
    log ""
    log "  🛑 BOOTSTRAP ABORTADO"
    log "  Motivo: $ABORT_REASON"
    log "  Os passos restantes não foram executados porque"
    log "  um passo CRÍTICO falhou."
  elif [[ $failed -gt 0 ]]; then
    log ""
    log "  ⚠️  BOOTSTRAP PARCIAL — $failed passo(s) falharam"
    log "  Corrija via SSH ou recriando o bastion."
  else
    log ""
    log "  ✅ BOOTSTRAP CONCLUÍDO COM SUCESSO"
  fi

  log ""
  log "  ✅ Instância permanece ATIVA como bastion (sem auto-terminate)."
  log "  Logs completos em: $LOG_FILE"
  log "══════════════════════════════════════════════════"
}
trap cleanup EXIT

# ── Passo CRÍTICO: se falha, marca todos os restantes como ABORTED ───────────
run_critical() {
  local step_name=$1
  shift

  if [[ "$ABORTED" == "true" ]]; then
    record "$step_name" "ABORTED" "CRITICAL"
    return 1
  fi

  log "────────────────────────────────────────────────"
  log "🔒 [CRÍTICO] $step_name"
  log "────────────────────────────────────────────────"

  if "$@"; then
    record "$step_name" "OK" "CRITICAL"
    return 0
  else
    record "$step_name" "FAIL" "CRITICAL"
    ABORTED=true
    ABORT_REASON="$step_name falhou"
    log "  🛑 Passo CRÍTICO falhou — abortando passos restantes"
    return 1
  fi
}

# ── Passo NORMAL: se falha, registra e continua ──────────────────────────────
run_step() {
  local step_name=$1
  shift

  if [[ "$ABORTED" == "true" ]]; then
    record "$step_name" "ABORTED" "NORMAL"
    return 1
  fi

  log "────────────────────────────────────────────────"
  log "🔄 $step_name"
  log "────────────────────────────────────────────────"

  if "$@"; then
    record "$step_name" "OK" "NORMAL"
    return 0
  else
    record "$step_name" "FAIL" "NORMAL"
    log "  ⚠️ Falhou, mas continuando para o próximo passo..."
    return 0  # Retorna 0 para não abortar
  fi
}

log "══════════════════════════════════════════════════"
log "  EKS BOOTSTRAP — $CLUSTER_NAME"
log "  Region: $REGION"
log "══════════════════════════════════════════════════"

# =============================================================================
# 🔑 AWS Credentials (hardcoded via aws_credentials.txt)
# =============================================================================
%{ if aws_credentials != "" ~}
setup_aws_credentials() {
  log "  Configurando credenciais AWS em ~/.aws/credentials..."
  mkdir -p /root/.aws
  cat > /root/.aws/credentials << 'AWS_CREDS_EOF'
${aws_credentials}
AWS_CREDS_EOF
  chmod 600 /root/.aws/credentials
  chmod 700 /root/.aws
  log "  ✅ Credenciais escritas em /root/.aws/credentials"
}
run_critical "Configurar AWS Credentials" setup_aws_credentials
%{ endif ~}

# =============================================================================
# 🔒 CRÍTICO: Dependências do sistema
# =============================================================================
install_system_deps() {
  dnf install -y unzip jq tar gzip --quiet 2>/dev/null || yum install -y unzip jq tar gzip --quiet
}
run_critical "Dependências do sistema" install_system_deps

# =============================================================================
# 🔒 CRÍTICO: kubectl
# =============================================================================
install_kubectl() {
  retry 3 5 "Download kubectl" \
    curl -sLo /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/v$KUBECTL_VERSION/bin/linux/amd64/kubectl"
  chmod +x /usr/local/bin/kubectl
  kubectl version --client 2>/dev/null
}
run_critical "kubectl v$KUBECTL_VERSION" install_kubectl

# =============================================================================
# 🔒 CRÍTICO: Helm
# =============================================================================
install_helm() {
  retry 3 5 "Download Helm" \
    curl -sL "https://get.helm.sh/helm-v$HELM_VERSION-linux-amd64.tar.gz" -o /tmp/helm.tar.gz
  tar xzf /tmp/helm.tar.gz -C /tmp
  mv /tmp/linux-amd64/helm /usr/local/bin/
  rm -rf /tmp/linux-amd64 /tmp/helm.tar.gz
  helm version --short
}
run_critical "Helm v$HELM_VERSION" install_helm

# =============================================================================
# 🔒 CRÍTICO: Kubeconfig + aguardar EKS API
# =============================================================================
configure_kubeconfig() {
  retry 10 15 "aws eks update-kubeconfig" \
    aws eks update-kubeconfig --name "$CLUSTER_NAME" --region "$REGION"

  log "  Debug: testando kubectl..."
  kubectl cluster-info 2>&1 || true

  log "  Aguardando nodes ficarem Ready (max 10 min)..."
  local timeout=600
  local elapsed=0
  while [[ $elapsed -lt $timeout ]]; do
    READY_NODES=0
    NODE_OUTPUT=$(kubectl get nodes --no-headers 2>&1) || true
    log "  Debug output: $NODE_OUTPUT"

    if echo "$NODE_OUTPUT" | grep -q " Ready"; then
      READY_NODES=$(echo "$NODE_OUTPUT" | grep -c " Ready") || READY_NODES=0
    fi

    if [[ "$READY_NODES" -gt 0 ]]; then
      log "  $READY_NODES node(s) Ready"
      kubectl get nodes -o wide
      return 0
    fi
    sleep 15
    elapsed=$((elapsed + 15))
    log "  Aguardando nodes... ($${elapsed}s/$${timeout}s)"
  done

  log "  Nenhum node Ready apos $${timeout}s"
  return 1
}
run_critical "Kubeconfig + Aguardar EKS" configure_kubeconfig

# =============================================================================
# 🔄 NORMAL: Namespaces
# =============================================================================
%{ if apply_namespaces && namespaces_yaml != "" ~}
apply_namespaces() {
  cat <<'NAMESPACES_EOF' | kubectl apply -f -
${namespaces_yaml}
NAMESPACES_EOF
}
run_step "Namespaces" apply_namespaces
%{ else ~}
record "Namespaces" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Metrics Server
# =============================================================================
%{ if install_metrics_server ~}
install_metrics_server() {
  # Usar versão pinada (v0.8.0+ tem bug com appProtocol no Service)
  local MS_VERSION="${metrics_server_version}"
  local MS_URL="https://github.com/kubernetes-sigs/metrics-server/releases/download/$MS_VERSION/components.yaml"

  log "  Baixando manifesto Metrics Server $MS_VERSION..."
  retry 3 10 "Download Metrics Server" \
    curl -sL "$MS_URL" -o /tmp/metrics-server.yaml

  # EKS: kubelet usa certificados auto-assinados — adicionar --kubelet-insecure-tls
  log "  Adicionando --kubelet-insecure-tls para compatibilidade com EKS..."
  sed -i 's/- --metric-resolution=15s/- --metric-resolution=15s\n        - --kubelet-insecure-tls/' /tmp/metrics-server.yaml

  retry 3 10 "Apply Metrics Server" \
    kubectl apply -f /tmp/metrics-server.yaml

  log "  Aguardando rollout (máx 5 min)..."
  kubectl -n kube-system rollout status deployment/metrics-server --timeout=300s
}
run_step "Metrics Server" install_metrics_server
%{ else ~}
record "Metrics Server" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Ingress NGINX
# =============================================================================
%{ if install_ingress_nginx && ingress_nginx_yaml != "" ~}
install_ingress_nginx() {
  cat <<'INGRESS_EOF' > /tmp/ingress-nginx.yaml
${ingress_nginx_yaml}
INGRESS_EOF

  retry 3 10 "Apply Ingress NGINX" \
    kubectl apply -f /tmp/ingress-nginx.yaml

  log "  Aguardando rollout (máx 5 min)..."
  kubectl -n ingress-nginx rollout status deployment/ingress-nginx-controller --timeout=300s

%{ if ingress_nginx_acm_yaml != "" ~}
  log "  Aplicando Service ACM/NLB..."
  cat <<'INGRESS_ACM_EOF' | kubectl apply -f -
${ingress_nginx_acm_yaml}
INGRESS_ACM_EOF
%{ endif ~}
}
run_step "Ingress NGINX" install_ingress_nginx
%{ else ~}
record "Ingress NGINX" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: External Secrets
# =============================================================================
%{ if install_external_secrets ~}
install_external_secrets() {
  retry 3 10 "Apply ESO CRDs" \
    kubectl apply -f 'https://raw.githubusercontent.com/external-secrets/external-secrets/main/deploy/crds/bundle.yaml' --server-side=true

  log "  Aguardando CRDs propagarem (30s)..."
  sleep 30

  retry 3 5 "Helm repo add" helm repo add external-secrets https://charts.external-secrets.io
  helm repo update

%{ if external_secrets_values != "" ~}
  cat <<'ESO_VALUES_EOF' > /tmp/external-secrets-values.yaml
${external_secrets_values}
ESO_VALUES_EOF

  retry 3 15 "Helm install external-secrets" \
    helm upgrade --install external-secrets external-secrets/external-secrets \
      --namespace kube-system \
      --version "$EXTERNAL_SECRETS_VERSION" \
      --values /tmp/external-secrets-values.yaml \
      --wait --timeout 5m0s
%{ else ~}
  retry 3 15 "Helm install external-secrets" \
    helm upgrade --install external-secrets external-secrets/external-secrets \
      --namespace kube-system \
      --version "$EXTERNAL_SECRETS_VERSION" \
      --wait --timeout 5m0s
%{ endif ~}
}
run_step "External Secrets Operator" install_external_secrets
%{ else ~}
record "External Secrets" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: ArgoCD
# =============================================================================
%{ if install_argocd ~}
install_argocd() {
  kubectl create namespace "$ARGOCD_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

  retry 3 5 "Helm repo add argo" helm repo add argo https://argoproj.github.io/argo-helm
  helm repo update

  retry 3 20 "Helm install argocd" \
    helm upgrade --install argocd argo/argo-cd \
      --namespace "$ARGOCD_NAMESPACE" \
      --version "$ARGOCD_VERSION" \
      --set server.service.type=ClusterIP \
      --set configs.params."server\.insecure"=true \
%{ if argocd_ingress_enabled && argocd_ingress_host != "" ~}
      --set configs.params."server\.rootpath"="${argocd_ingress_path}" \
%{ endif ~}
      --set dex.enabled=false \
      --set notifications.enabled=false \
      --wait --timeout 8m0s

  log "  Aguardando rollout (máx 3 min)..."
  kubectl -n "$ARGOCD_NAMESPACE" rollout status deployment/argocd-server --timeout=180s

%{ if argocd_ingress_enabled && argocd_ingress_host != "" ~}
  log "  Aplicando Ingress do ArgoCD (path: ${argocd_ingress_path})..."
  cat <<'ARGOCD_INGRESS_EOF' | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: argocd-server-ingress
  namespace: ${argocd_namespace}
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
spec:
  ingressClassName: nginx
  rules:
    - host: ${argocd_ingress_host}
      http:
        paths:
          - path: ${argocd_ingress_path}
            pathType: Prefix
            backend:
              service:
                name: argocd-server
                port:
                  number: 80
ARGOCD_INGRESS_EOF
%{ endif ~}

  # Capturar senha
  local argocd_pass
  argocd_pass=$(kubectl -n "$ARGOCD_NAMESPACE" get secret argocd-initial-admin-secret \
    -o jsonpath="{.data.password}" 2>/dev/null | base64 -d || echo "INDISPONÍVEL")

  log "  ┌──────────────────────────────────────────┐"
  log "  │ 🔑 ArgoCD Password: $argocd_pass"
%{ if argocd_ingress_enabled && argocd_ingress_host != "" ~}
  log "  │ 🌐 URL: https://${argocd_ingress_host}${argocd_ingress_path}"
%{ endif ~}
  log "  │ 📌 Salve! Visível no System Log da EC2  │"
  log "  └──────────────────────────────────────────┘"
}
run_step "ArgoCD" install_argocd
%{ else ~}
record "ArgoCD" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Manifestos adicionais (post-install)
# =============================================================================
%{ if length(additional_manifests) > 0 ~}
%{ if install_argocd ~}
# ArgoCD instalado: aguardar CRDs (Application, AppProject) ficarem
# Established antes de aplicar manifestos que podem usá-los.
wait_argocd_crds() {
  log "  Aguardando CRD applications.argoproj.io..."
  retry 6 10 "wait CRD applications.argoproj.io" \
    kubectl wait --for=condition=Established \
    crd/applications.argoproj.io --timeout=30s
  log "  Aguardando CRD appprojects.argoproj.io..."
  retry 3 5 "wait CRD appprojects.argoproj.io" \
    kubectl wait --for=condition=Established \
    crd/appprojects.argoproj.io --timeout=30s
}
run_step "Aguardar CRDs do ArgoCD" wait_argocd_crds
%{ endif ~}

# Escrever cada manifesto em arquivo separado
mkdir -p /tmp/additional-manifests
%{ for name, yaml_content in additional_manifests ~}
cat <<'MANIFEST_EOF' > /tmp/additional-manifests/${name}.yaml
${yaml_content}
MANIFEST_EOF
%{ endfor ~}

# Aplicar cada manifesto em ordem (alfabética), com retry e step próprio
%{ for name, yaml_content in additional_manifests ~}
apply_${replace(replace(name, "-", "_"), ".", "_")}() {
  retry 3 10 "kubectl apply ${name}" \
    kubectl apply -f /tmp/additional-manifests/${name}.yaml
}
run_step "Manifesto: ${name}" apply_${replace(replace(name, "-", "_"), ".", "_")}
%{ endfor ~}
%{ else ~}
record "Manifestos adicionais" "SKIP" "NORMAL"
%{ endif ~}

# =============================================================================
# 🔄 NORMAL: Comandos extras
# =============================================================================
%{ if extra_commands != "" ~}
run_extra() {
${extra_commands}
}
run_step "Comandos extras" run_extra
%{ endif ~}

# =============================================================================
# 🔄 Verificação final (sempre roda, mesmo com falhas)
# =============================================================================
if [[ "$ABORTED" != "true" ]]; then
  verify_cluster() {
    echo ""
    log "── Nodes ──"
    kubectl get nodes -o wide 2>/dev/null || true
    echo ""
    log "── Namespaces ──"
    kubectl get namespaces 2>/dev/null || true
    echo ""
    log "── Pods (all namespaces) ──"
    kubectl get pods --all-namespaces 2>/dev/null || true
    echo ""
    log "── Services ──"
    kubectl get svc -A 2>/dev/null || true
    echo ""
  }
  run_step "Verificação final" verify_cluster
fi

# O trap EXIT chama cleanup() → mostra RELATÓRIO COMPLETO (sem shutdown)
exit 0