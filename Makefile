# =============================================================================
# SolidaryTech Infrastructure - Makefile
# =============================================================================
# Uso:
#   make init ENV=dev         # Inicializa backend e baixa módulos
#   make plan ENV=dev         # Mostra mudanças planejadas
#   make apply ENV=dev        # Aplica mudanças (com confirmação)
#   make destroy ENV=dev      # Destrói infraestrutura
#   make fmt                  # Formata todo o código Terraform
#   make validate             # Valida sintaxe + referências
#   make lint                 # Roda tflint (se instalado)
#   make security             # Roda checkov (se instalado)
# =============================================================================

ENV ?= dev
TF_DIR := .

.DEFAULT_GOAL := help

# -----------------------------------------------------------------------------
# Cores
# -----------------------------------------------------------------------------
CYAN   := \033[0;36m
GREEN  := \033[0;32m
YELLOW := \033[1;33m
RED    := \033[0;31m
NC     := \033[0m

.PHONY: help
help: ## Mostra esta mensagem de ajuda
	@printf "$(CYAN)SolidaryTech Infrastructure$(NC)\n"
	@printf "$(YELLOW)Uso:$(NC) make <comando> [ENV=dev|prod]\n\n"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

# -----------------------------------------------------------------------------
# Validação de ENV
# -----------------------------------------------------------------------------
.PHONY: check-env
check-env:
	@if [ ! -d "envs/$(ENV)" ]; then \
		printf "$(RED)✗ Ambiente '$(ENV)' não existe (envs/$(ENV)/)$(NC)\n"; \
		exit 1; \
	fi

# -----------------------------------------------------------------------------
# Inicialização
# -----------------------------------------------------------------------------
.PHONY: init
init: check-env ## Inicializa backend e baixa módulos do Git
	@printf "$(CYAN)→ Inicializando Terraform para $(ENV)...$(NC)\n"
	terraform -chdir=$(TF_DIR) init \
		-backend-config=envs/$(ENV)/backend.hcl \
		-reconfigure

.PHONY: init-no-backend
init-no-backend: ## Init sem backend (útil para fmt/validate locais)
	terraform -chdir=$(TF_DIR) init -backend=false

# -----------------------------------------------------------------------------
# Workflow principal
# -----------------------------------------------------------------------------
.PHONY: plan
plan: check-env ## Mostra mudanças planejadas
	@printf "$(CYAN)→ Planejando mudanças para $(ENV)...$(NC)\n"
	terraform -chdir=$(TF_DIR) plan \
		-var-file=envs/$(ENV)/terraform.tfvars \
		-out=envs/$(ENV)/tfplan.bin

.PHONY: apply
apply: check-env ## Aplica mudanças planejadas (use 'make plan' antes)
	@if [ ! -f "envs/$(ENV)/tfplan.bin" ]; then \
		printf "$(YELLOW)⚠ tfplan.bin não encontrado. Rodando plan...$(NC)\n"; \
		$(MAKE) plan ENV=$(ENV); \
	fi
	@printf "$(CYAN)→ Aplicando para $(ENV)...$(NC)\n"
	terraform -chdir=$(TF_DIR) apply envs/$(ENV)/tfplan.bin
	@rm -f envs/$(ENV)/tfplan.bin

.PHONY: destroy
destroy: check-env ## Destrói toda a infraestrutura (requer confirmação)
	@printf "$(RED)⚠ ATENÇÃO: vai destruir TUDO em $(ENV)$(NC)\n"
	@read -p "Digite '$(ENV)' para confirmar: " confirm && [ "$$confirm" = "$(ENV)" ] || (printf "$(RED)Abortado.$(NC)\n"; exit 1)
	terraform -chdir=$(TF_DIR) destroy \
		-var-file=envs/$(ENV)/terraform.tfvars

# -----------------------------------------------------------------------------
# Qualidade de Código
# -----------------------------------------------------------------------------
.PHONY: fmt
fmt: ## Formata todo o código Terraform
	@printf "$(CYAN)→ Formatando código...$(NC)\n"
	terraform fmt -recursive $(TF_DIR)
	@printf "$(GREEN)✓ Formatação aplicada$(NC)\n"

.PHONY: fmt-check
fmt-check: ## Verifica formatação sem alterar (uso em CI)
	@terraform fmt -check -recursive $(TF_DIR) && \
		printf "$(GREEN)✓ Código bem formatado$(NC)\n" || \
		(printf "$(RED)✗ Código mal formatado. Rode: make fmt$(NC)\n"; exit 1)

.PHONY: validate
validate: init-no-backend ## Valida sintaxe e referências
	@printf "$(CYAN)→ Validando sintaxe...$(NC)\n"
	terraform -chdir=$(TF_DIR) validate

.PHONY: lint
lint: ## Roda tflint (precisa ter tflint instalado)
	@command -v tflint >/dev/null 2>&1 || { printf "$(RED)tflint não instalado$(NC)\n"; exit 1; }
	@printf "$(CYAN)→ Rodando tflint...$(NC)\n"
	tflint --recursive

.PHONY: security
security: ## Roda checkov (precisa ter checkov instalado)
	@command -v checkov >/dev/null 2>&1 || { printf "$(RED)checkov não instalado$(NC)\n"; exit 1; }
	@printf "$(CYAN)→ Rodando checkov...$(NC)\n"
	checkov -d $(TF_DIR) --quiet --compact

.PHONY: check
check: fmt-check validate ## Roda fmt-check + validate (CI-friendly)

# -----------------------------------------------------------------------------
# Utilidades
# -----------------------------------------------------------------------------
.PHONY: output
output: check-env ## Mostra outputs do estado atual
	terraform -chdir=$(TF_DIR) output

.PHONY: state-list
state-list: check-env ## Lista todos os recursos no state
	terraform -chdir=$(TF_DIR) state list

.PHONY: clean
clean: ## Remove arquivos temporários locais (NÃO mexe no state)
	@printf "$(YELLOW)→ Limpando arquivos locais...$(NC)\n"
	find . -name ".terraform" -type d -prune -exec rm -rf {} +
	find . -name ".terraform.lock.hcl" -delete
	find . -name "tfplan.bin" -delete
	@printf "$(GREEN)✓ Limpo$(NC)\n"
