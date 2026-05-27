# SolidaryTech Infrastructure — Fase 5 (Terraform)

> **Hackathon FIAP DevOps — Fase 5 — Etapa 2: Infrastructure as Code**

Infraestrutura AWS provisionada via Terraform para a plataforma **SolidaryTech**, composta por 3 microsserviços (`ngo-service`, `donation-service`, `volunteer-service`) deployados em Amazon EKS.

---

## 🏗️ Arquitetura

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Account                            │
│                                                                 │
│  ┌──────────────────── VPC 10.0.0.0/20 ────────────────────┐   │
│  │                                                         │   │
│  │  ┌─ Public Subnets (2 AZ) ─┐  ┌─ Private Subnets ──┐  │   │
│  │  │                          │  │                     │  │   │
│  │  │  ┌──────────┐            │  │  ┌──────────────┐  │  │   │
│  │  │  │   VPN    │            │  │  │ EKS Workers  │  │  │   │
│  │  │  │ Pritunl  │ ←──VPN──── │  │  │  (3 ns:      │  │  │   │
│  │  │  │   EC2    │   tunnel   │  │  │   ngo,       │  │  │   │
│  │  │  └──────────┘            │  │  │   donation,  │  │  │   │
│  │  │                          │  │  │   volunteer) │  │  │   │
│  │  │  ┌──────────┐            │  │  └──────────────┘  │  │   │
│  │  │  │   NAT    │ ←─Egress── │  │  ┌──────────────┐  │  │   │
│  │  │  │ Gateway  │            │  │  │ RDS Postgres │  │  │   │
│  │  │  └──────────┘            │  │  │ (ngo + don.) │  │  │   │
│  │  │                          │  │  └──────────────┘  │  │   │
│  │  └──────────────────────────┘  └─────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────┘   │
│                                                                 │
│  ┌── DynamoDB ──┐  ┌─ SQS ─────────────┐  ┌── ECR ────────┐    │
│  │  Volunteers  │  │ donations + DLQ + │  │ 3 repos       │    │
│  │  (PITR=ON)   │  │ CloudWatch Alarms │  │ (1 per service)│   │
│  └──────────────┘  └───────────────────┘  └───────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Recursos Provisionados

| Recurso | Quantidade | Observações |
|---|---|---|
| VPC | 1 | `10.0.0.0/20` com auto-discovery do EKS |
| Subnets | 4 | 2 públicas + 2 privadas (multi-AZ) |
| NAT Gateway | 1 | Single NAT (FinOps: dev/prod -$32/mês vs HA) |
| EKS Cluster | 1 | API server **privado**, acesso via VPN |
| RDS PostgreSQL | 2 | `ngo_db` + `donation_db` (for_each) |
| DynamoDB Table | 1 | `volunteers` (PAY_PER_REQUEST + PITR) |
| ECR | 3 | 1 repo por microsserviço (for_each, IMMUTABLE) |
| SQS | 2 | Fila `donations` + Dead Letter Queue |
| CloudWatch Alarms | 2 | DLQ não-vazia + idade da msg mais antiga |
| EC2 VPN | 1 | Pritunl com Elastic IP |

---

## 📁 Estrutura

```
solidarytech-infrastructure/
├── main.tf              # 🎯 Declarativo: SÓ chamadas de módulos
├── variables.tf         # 🌐 Globais: region, project, environment, tags
├── outputs.tf           # 📤 Outputs agregados
├── providers.tf         # 🔌 AWS provider + default_tags
├── backend.tf           # 💾 Backend S3 (config via .hcl)
├── data.tf              # 🔍 LabRole, AZs
├── locals.tf            # 🏷️  Tags FinOps + microsserviços
├── Makefile             # 🛠️  Automação (init, plan, apply, fmt, validate)
│
├── modules/
│   ├── networking/      # VPC + Security Groups
│   ├── registry/        # ECR (for_each)
│   ├── messaging/       # SQS + DLQ + Alarms
│   ├── databases/       # RDS (for_each) + DynamoDB
│   ├── vpn/             # Pritunl EC2
│   └── platform/        # EKS + Bootstrap
│       └── kubernetes/  # namespaces, ingress, external-secrets
│
└── envs/
    ├── dev/             # backend.hcl + terraform.tfvars
    └── prod/            # backend.hcl + terraform.tfvars
```

---

## 🚀 Como Usar

### Pré-requisitos

- **Terraform** >= 1.15.3 (versão estável atual, mai/2026 — inclui lock nativo S3)
- **AWS Provider** ~> 6.46 (versão mais recente, mai/2026)
- **AWS CLI** configurado
- **AWS Academy** com sessão ativa (`Lab > Show > AWS Details`)
- Bucket S3 versionado para o backend (criado separadamente)

### 1. Criar o bucket S3 do backend (uma vez por ambiente)

O state remoto requer um bucket S3 com versionamento. O **lock é nativo do S3** (`use_lockfile=true`) — não precisa de DynamoDB.

```bash
# DEV
aws s3api create-bucket \
  --bucket solidarytech-terraform-state-dev \
  --region us-east-1

aws s3api put-bucket-versioning \
  --bucket solidarytech-terraform-state-dev \
  --versioning-configuration Status=Enabled

aws s3api put-public-access-block \
  --bucket solidarytech-terraform-state-dev \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicAcls=true"

# Repita para PROD trocando o nome do bucket
```

> 💡 **Por que sem DynamoDB?** A partir do Terraform 1.10 (nov/2024), o backend S3 oferece **lock nativo** via conditional writes (`PutObject` com `If-None-Match`). A configuração `dynamodb_table` foi **deprecada** pela HashiCorp. Resultado: 1 recurso a menos pra gerenciar e zero custo de lock.

### 2. Configurar credenciais

```bash
# Pegue as credenciais do AWS Academy:
#   Lab > AWS Details > Show > Cloud Access > AWS CLI
export TF_VAR_aws_access_key_id="ASIA..."
export TF_VAR_aws_secret_access_key="..."
export TF_VAR_aws_session_token="..."
```

### 3. Inicializar

```bash
make init ENV=dev
```

### 4. Planejar e aplicar

```bash
make plan ENV=dev    # Mostra o que será criado
make apply ENV=dev   # Aplica (gasta cota Academy)
```

### 5. Acessar o cluster

Como o EKS é **privado**, você precisa:
1. Conectar na VPN Pritunl (IP em `make output`)
2. Gerar kubeconfig: `aws eks update-kubeconfig --name solidarytech-dev-eks --region us-east-1`
3. Testar: `kubectl get nodes`

### 6. Destruir (quando terminar)

```bash
make destroy ENV=dev   # Requer digitar 'dev' para confirmar
```

---

## 🛠️ Comandos Disponíveis (Makefile)

```bash
make help              # Mostra todos os comandos
make init ENV=dev      # Inicializa backend e baixa módulos
make plan ENV=dev      # Planeja mudanças
make apply ENV=dev     # Aplica mudanças
make destroy ENV=dev   # Destrói tudo (com confirmação)
make fmt               # Formata todo o código
make fmt-check         # Verifica formatação (CI)
make validate          # Valida sintaxe
make lint              # Roda tflint (precisa instalar)
make security          # Roda checkov (precisa instalar)
make check             # fmt-check + validate (CI-friendly)
make output            # Mostra outputs do estado
make clean             # Limpa arquivos locais temporários
```

---

## 🎯 Melhorias Aplicadas (Feedback Fase 4 → Fase 5)

| # | Feedback do Avaliador | Aplicação |
|---|---|---|
| 1 | ✅ Separar módulos em diretórios | 6 módulos em `modules/<name>/` |
| 2 | ✅ Main.tf root limpo e declarativo | ~100 linhas, só chamadas `module` |
| 3 | ✅ Variables.tf gigante quebrado | Cada módulo tem o seu (10-30 vars) |
| 4 | ✅ for_each em vez de blocos repetidos | ECR (era 5 blocos), RDS (era 3) |
| 5 | ✅ Type em todas as variáveis | `string`, `number`, `bool`, `map(object())`, `list()` |
| 6 | ✅ Nomenclatura consistente | Tudo em inglês: `Environment`, sem `Ambiente` |
| 7 | ✅ Sem 0.0.0.0/0 em SG ingress | Referência a outros SGs ou CIDR da VPC |
| 8 | ✅ Sem `latest` em Docker tags | `mongo:7.0.14`, `pritunl:1.32.4805.95-3` |
| 9 | ✅ Sources Git com hash imutável | Maioria pinada (2 com TODO documentado) |

---

## 🏷️ Tags FinOps

Todos os recursos recebem automaticamente (via `default_tags` no provider):

```hcl
{
  Project     = "SolidaryTech"
  Environment = "dev" | "prod"
  CostCenter  = "NGO-Core"
  Owner       = "DevOps-Team"
  ManagedBy   = "Terraform"
}
```

Recursos individuais ainda recebem `Service = "<name>"` para discriminação granular no Cost Explorer.

---

## 🔐 Segurança

- ✅ **EKS API server privado** (acesso só via VPN)
- ✅ **RDS sem IP público** (subnet privada, ingress apenas dos EKS workers)
- ✅ **Senhas RDS no Secrets Manager** (não ficam no Terraform state)
- ✅ **EBS criptografado** (workers e VPN)
- ✅ **ECR com IMMUTABLE tags** + scan on push
- ✅ **IMDSv2 obrigatório** nos workers (`http_tokens = required`)
- ✅ **SQS com SSE-managed encryption**
- ✅ **DynamoDB criptografada** + PITR habilitado

---

## ⚠️ Limitações AWS Academy

| Limitação | Workaround |
|---|---|
| Não pode criar IAM Roles | Usa `LabRole` pré-existente |
| Não pode criar Instance Profiles | Usa `LabInstanceProfile` |
| Não pode criar KMS Keys | Usa encryption gerenciada pela AWS (SSE-S3, SSE-SQS) |
| Sem OIDC/IRSA | Credenciais via `Secret` K8s (rotacionar a cada sessão) |
| Sessão expira em ~4h | Reaplicar com credenciais novas |

---

## 📚 Próximas Etapas (Roadmap Hackathon Fase 5)

- [ ] **Etapa 3**: Manifestos Kubernetes dos 3 microsserviços via Helm/Kustomize
- [ ] **Etapa 4**: CI/CD via GitHub Actions (Trivy, Sonar, push ECR)
- [ ] **Etapa 5**: ArgoCD + GitOps para deploy contínuo
- [ ] **Etapa 6**: Observabilidade (Prometheus + Grafana + Loki + OTel)
- [ ] **Etapa 7**: SRE — SLI/SLO + Dashboard Error Budget do donation-service
- [ ] **Etapa 8**: FinOps — Forecast + rightsizing
- [ ] **Etapa 9**: AIOps — Watchdog + alarmes automatizados
- [ ] **Etapa 10**: DR — Multi-region failover (Velero/Backup-Restore)

---