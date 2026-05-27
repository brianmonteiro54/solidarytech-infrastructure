# =============================================================================
# Backend Config - DEV
# =============================================================================
# Uso:
#   terraform init -backend-config=envs/dev/backend.hcl
#
# Pré-requisito: criar o bucket S3 manualmente uma única vez:
#   aws s3api create-bucket \
#     --bucket solidarytech-terraform-state-dev \
#     --region us-east-1
#   aws s3api put-bucket-versioning \
#     --bucket solidarytech-terraform-state-dev \
#     --versioning-configuration Status=Enabled
# =============================================================================

key          = "dev/terraform.tfstate"
region       = "us-east-1"
encrypt      = true
use_lockfile = true
