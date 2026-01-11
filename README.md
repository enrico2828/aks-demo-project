# Azure-native AKS Demo (Terraform)

An enterprise-style AKS platform for architecture practice (AZ-305) and demonstration purposes.

## What's deployed

| Resource | Description |
|----------|-------------|
| **Resource Group** | `aks-demo01-dev-weu-rg` |
| **VNet** | `aks-demo01-dev-weu-vnet` with subnets for AKS, jumpbox, and private endpoints |
| **AKS Cluster** | Private cluster with Azure CNI Overlay, Entra ID integration, Azure RBAC for Kubernetes |
| **Jumpbox VM** | Linux VM for cluster administration (SSH + optional public IP) |
| **Log Analytics** | Central logging for Container Insights and control plane logs |
| **Terraform State** | Remote state in Azure Storage (Azure AD auth, no storage keys) |

### Security posture

- **Private AKS** — API server is not exposed to the internet
- **Entra ID authentication** — no local Kubernetes accounts; `--admin` credential disabled
- **Azure RBAC for Kubernetes** — authorization via Azure role assignments
- **Azure Policy for Kubernetes** — Pod Security Standards (baseline or restricted)
- **Microsoft Defender for Containers** — runtime threat detection (disabled in CI for least-privilege)
- **Container Insights** — full observability with Log Analytics
- **Network Policy (Azure NPM)** — micro-segmentation for pod-to-pod traffic
- **Image Cleaner** — automatic removal of stale/vulnerable images from nodes
- **Run Command disabled** — prevents `az aks command invoke` access
- **Jumpbox hardened** — SSH keys only, explicit CIDR allow-list, no password auth

## Repository layout

```
.github/
└── workflows/
    └── infra-terraform.yml   # Infra CI/CD (validate/plan/apply)
infra/
├── bootstrap/bicep/          # Bicep templates for bootstrapping (RGs + tfstate storage)
│   ├── bootstrap.bicep       # Main subscription-level deployment
│   ├── bootstrap.bicepparam  # Parameters file
│   └── modules/
│       └── storage.bicep     # Storage account module
└── terraform/
    ├── modules/
    │   ├── aks/              # AKS cluster module
    │   ├── aks-security/     # Security controls (Log Analytics, Policy, Defender)
    │   ├── jumpbox/          # Jumpbox VM module
    │   └── network/          # VNet + subnets module
    ├── *.tf                  # Root module
    └── backend.hcl           # Backend configuration
```

## Prerequisites

- Azure CLI (`az`) authenticated to the target subscription
- Terraform >= 1.5
- An Entra ID security group for AKS administrators
- **Storage Blob Data Contributor** role on the tfstate storage account (for local Terraform runs)

---

## Quick start

### 1. Bootstrap resource groups and Terraform state

The Bicep bootstrap creates **both resource groups** (tfstate + infra) and the storage account.
This is a subscription-level deployment, enabling true least-privilege for Terraform.

```zsh
az login

# Subscription-level deployment (creates RGs + storage)
az deployment sub create \
  --location westeurope \
  --template-file infra/bootstrap/bicep/bootstrap.bicep \
  --parameters infra/bootstrap/bicep/bootstrap.bicepparam

# Verify outputs
az deployment sub show \
  --name bootstrap \
  --query properties.outputs

# Grant yourself Storage Blob Data Contributor for local Terraform runs
# (The backend uses Azure AD auth, not storage keys)
TFSTATE_STORAGE_ACCOUNT=$(az deployment sub show --name bootstrap --query properties.outputs.storageAccountName.value -o tsv)
TFSTATE_RG=$(az deployment sub show --name bootstrap --query properties.outputs.tfstateResourceGroupName.value -o tsv)

az role assignment create \
  --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$TFSTATE_RG/providers/Microsoft.Storage/storageAccounts/$TFSTATE_STORAGE_ACCOUNT"
```

> **Note:** Edit `infra/bootstrap/bicep/bootstrap.bicepparam` to customize prefix, environment, location, etc.

### 2. Create Entra ID admin group

```zsh
az ad group create \
  --display-name "aks-demo01-cluster-admins" \
  --mail-nickname "aks-demo01-cluster-admins" \
  --description "AKS cluster administrators"

# Get the group object ID
az ad group show --group "aks-demo01-cluster-admins" --query id -o tsv

# Add yourself to the group
az ad group member add \
  --group "aks-demo01-cluster-admins" \
  --member-id "$(az ad signed-in-user show --query id -o tsv)"
```

### 3. Configure Terraform

```zsh
cd infra/terraform

# Initialize with remote backend
terraform init -backend-config=backend.hcl

# Create local configuration (not committed)
cp jumpbox.auto.tfvars.example jumpbox.auto.tfvars
```

Edit `jumpbox.auto.tfvars`:

```hcl
# SSH public key (RSA format)
jumpbox_ssh_public_key = "ssh-rsa AAAA..."

# Enable public IP for SSH access
jumpbox_assign_public_ip  = true
jumpbox_allowed_ssh_cidrs = ["<your-ip>/32"]

# Install az, kubectl, kubelogin on jumpbox
jumpbox_bootstrap_tools = true

# Entra ID group for AKS admin access (required)
aks_admin_group_object_ids = ["<group-object-id>"]
```

### 4. Deploy

```zsh
terraform apply
```

---

## GitHub Actions CI/CD

The repo includes a workflow for infrastructure deployments using **Azure OIDC** (no stored credentials).

| Workflow | Trigger | Action |
|----------|---------|--------|
| `infra-terraform.yml` | PR to main/develop | Validate + Plan (comments on PR) |
| `infra-terraform.yml` | Push to main | Apply |

### Setup: Azure OIDC for GitHub Actions

#### 1. Create an App Registration

```zsh
az ad app create --display-name "github-actions-aks-demo"

# Note the appId (client ID)
APP_ID=$(az ad app list --display-name "github-actions-aks-demo" --query "[0].appId" -o tsv)
```

#### 2. Create a Service Principal and assign least-privilege roles

```zsh
az ad sp create --id $APP_ID

# Set these to match your naming convention (see variables.tf)
PREFIX="aks-demo01"        # var.prefix
ENVIRONMENT="dev"          # var.environment
LOCATION_CODE="weu"        # westeurope → weu, northeurope → neu

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
INFRA_RG="${PREFIX}-${ENVIRONMENT}-${LOCATION_CODE}-rg"
TFSTATE_RG="${PREFIX}-${LOCATION_CODE}-tfstate-rg"
TFSTATE_STORAGE_ACCOUNT=$(az deployment sub show --name bootstrap --query properties.outputs.storageAccountName.value -o tsv)

# Contributor on the infra resource group (create/update/delete resources)
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$INFRA_RG"

# Storage Blob Data Contributor on the tfstate storage account (read/write state blobs)
az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$TFSTATE_RG/providers/Microsoft.Storage/storageAccounts/$TFSTATE_STORAGE_ACCOUNT"
```

#### 3. Add Federated Credential for GitHub

```zsh
# This workflow uses GitHub Environments (env: dev). When a job runs with
# `environment: dev`, GitHub's OIDC subject looks like:
#   repo:<owner>/<repo>:environment:dev

az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "gha-aks-demo-project-env-dev",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:enrico2828/aks-demo-project:environment:dev",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

#### 4. Add GitHub Environment Secrets

Create an environment named **dev**: **Settings → Environments → New environment → `dev`**

Add secrets:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `$APP_ID` (from step 1) |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |
| `JUMPBOX_SSH_PUBLIC_KEY` | Contents of your SSH public key |
| `AKS_ADMIN_GROUP_OBJECT_IDS` | JSON array, e.g. `["6b496cdf-..."]` |
| `JUMPBOX_ALLOWED_SSH_CIDRS` | JSON array, e.g. `["1.2.3.4/32"]` |

> **Note:** Defender for Containers is disabled in CI because it requires subscription-level permissions (`Microsoft.Security/pricings/*`) that would violate least-privilege. Enable it locally if needed.

---

## Accessing AKS

The AKS API server is private — access it from the jumpbox.

### Connect to jumpbox

```zsh
# Get the public IP
terraform output jumpbox_public_ip

# SSH (use IdentitiesOnly to avoid "too many auth failures")
ssh -o IdentitiesOnly=yes -i ~/.ssh/aks-demo-jumpbox-rsa azureuser@<jumpbox_public_ip>
```

Or add to `~/.ssh/config`:

```sshconfig
Host aks-demo-jumpbox
  HostName <jumpbox_public_ip>
  User azureuser
  IdentityFile ~/.ssh/aks-demo-jumpbox-rsa
  IdentitiesOnly yes
```

### Access AKS from jumpbox

```zsh
az login
az aks get-credentials --resource-group aks-demo01-dev-weu-rg --name aks-demo01-dev-weu-aks --overwrite-existing
kubectl get nodes
```

The jumpbox includes:
- `kubectl` with bash completion
- `k` alias for `kubectl`
- `kubelogin` for Entra ID token handling

---

## Cleanup

### Quick cleanup (Terraform only)

This repo uses `lifecycle.prevent_destroy` to protect critical resources (AKS cluster, jumpbox public IP).

To destroy:

1. Temporarily set `prevent_destroy = false` in:
   - `infra/terraform/modules/aks/main.tf`
   - `infra/terraform/modules/jumpbox/main.tf`
2. Run `terraform destroy`
3. Re-enable `prevent_destroy = true` if you plan to keep using the repo.

### Full cleanup (remove everything from Azure)

This removes all Terraform-managed infrastructure, bootstrap resources, and manually-created identities.

#### 1) Destroy Terraform-managed infrastructure

```zsh
cd infra/terraform
terraform destroy
```

#### 2) Delete bootstrap resource groups

```zsh
INFRA_RG=$(az deployment sub show --name bootstrap --query properties.outputs.infraResourceGroupName.value -o tsv)
TFSTATE_RG=$(az deployment sub show --name bootstrap --query properties.outputs.tfstateResourceGroupName.value -o tsv)

az group delete --name "$INFRA_RG" --yes --no-wait
az group delete --name "$TFSTATE_RG" --yes --no-wait
```

#### 3) Remove your local tfstate role assignment

```zsh
TFSTATE_STORAGE_ACCOUNT=$(az deployment sub show --name bootstrap --query properties.outputs.storageAccountName.value -o tsv)
TFSTATE_RG=$(az deployment sub show --name bootstrap --query properties.outputs.tfstateResourceGroupName.value -o tsv)

az role assignment delete \
  --assignee "$(az ad signed-in-user show --query id -o tsv)" \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$(az account show --query id -o tsv)/resourceGroups/$TFSTATE_RG/providers/Microsoft.Storage/storageAccounts/$TFSTATE_STORAGE_ACCOUNT"
```

#### 4) Delete GitHub Actions Entra app

```zsh
APP_ID=$(az ad app list --display-name "github-actions-aks-demo" --query "[0].appId" -o tsv)
az ad app delete --id "$APP_ID"
```

#### 5) Delete the demo Entra admin group (optional)

```zsh
az ad group delete --group "aks-demo01-cluster-admins"
```

---

## Terraform outputs

| Output | Description |
|--------|-------------|
| `aks_name` | AKS cluster name |
| `aks_private_fqdn` | Private FQDN of the API server |
| `aks_oidc_issuer_url` | OIDC issuer URL (for Workload Identity) |
| `jumpbox_public_ip` | Jumpbox public IP (if enabled) |
| `jumpbox_private_ip` | Jumpbox private IP |
| `aks_access_commands` | Ready-to-copy commands for AKS access |
| `log_analytics_workspace_id` | Log Analytics workspace resource ID |
| `security_features_enabled` | Summary of security features enabled |

---

## Configuration reference

Key variables (see `variables.tf` for full list):

### General

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `westeurope` | Azure region |
| `prefix` | `aks-demo01` | Resource naming prefix |
| `environment` | `dev` | Environment tag |
| `aks_admin_group_object_ids` | — | Entra ID group(s) for cluster admin |
| `jumpbox_vm_size` | `Standard_D2s_v6` | VM size for the jumpbox |
| `jumpbox_bootstrap_tools` | `false` | Install az/kubectl/kubelogin via cloud-init |
| `aks_system_node_vm_size` | `Standard_D2s_v6` | VM size for AKS system node pool |

### Security hardening

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_azure_policy` | `true` | Enable Azure Policy for Kubernetes |
| `azure_policy_level` | `baseline` | `baseline` (PSS baseline) or `restricted` |
| `azure_policy_effect` | `deny` | `audit` for visibility, `deny` for enforcement |
| `enable_defender_for_containers` | `true` | Enable Microsoft Defender for Containers |
| `aks_network_policy` | `azure` | Network policy: `azure`, `calico`, or `null` |
| `image_cleaner_enabled` | `true` | Remove stale/vulnerable images from nodes |
| `aks_run_command_enabled` | `false` | Allow `az aks command invoke` |

---

## Architecture notes

### Network

| CIDR | Purpose |
|------|---------|
| `10.10.0.0/16` | VNet |
| `10.10.0.0/22` | AKS subnet (1024 addresses) |
| `10.10.4.0/24` | Private endpoints subnet |
| `10.10.5.0/27` | Jumpbox subnet (32 addresses) |
| `192.168.0.0/16` | Pod CIDR (overlay) |
| `10.20.0.0/16` | Service CIDR |

### AKS configuration

- **Network plugin**: Azure CNI Overlay
- **Network policy**: Azure NPM
- **Private cluster**: Yes
- **Local accounts**: Disabled (Entra ID only)
- **OIDC issuer**: Enabled (for Workload Identity)
- **System node pool**: 1 node, `Standard_D2s_v6`
- **Azure Policy**: Gatekeeper-based pod security enforcement
- **Image Cleaner**: Automatic cleanup (48h interval)
- **Run command**: Disabled

### Security controls

| Control | Implementation |
|---------|----------------|
| **Identity** | Entra ID + Azure RBAC for Kubernetes |
| **Network** | Private cluster + Azure Network Policy |
| **Policy** | Azure Policy (Pod Security Standards) |
| **Detection** | Microsoft Defender for Containers |
| **Logging** | Container Insights + control plane audit logs |
| **Secrets** | Key Vault Secrets Provider (CSI driver, optional) |
| **Images** | Image Cleaner for stale image removal |

### Authentication flow

1. User SSHs to jumpbox
2. `az login` authenticates to Entra ID
3. `az aks get-credentials` fetches kubeconfig (configured for Entra auth)
4. `kubectl` commands use `kubelogin` to obtain tokens
5. AKS validates the token and checks Azure RBAC role assignments

---

## Next steps

Planned additions:

- ACR (Azure Container Registry) with private endpoint
- Key Vault integration with CSI driver
- Application workloads with Workload Identity
- Network policies for workload segmentation
- Alerting (Action Group + metric/log alerts)

## Out of scope

The following are useful for production but excluded from this demo due to cost:

- **Azure Managed Grafana + Prometheus** — ~€150/month for Grafana. Container Insights provides sufficient monitoring.
- **Azure Front Door / Application Gateway** — Ingress with WAF.
- **Azure Firewall** — Egress filtering (~€900/month).
