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
| **Terraform State** | Remote state in Azure Storage |

### Security posture

- **Private AKS** — API server is not exposed to the internet
- **Entra ID authentication** — no local Kubernetes accounts; `--admin` credential disabled
- **Azure RBAC for Kubernetes** — authorization via Azure role assignments
- **Azure Policy for Kubernetes** — Pod Security Standards (baseline or restricted)
- **Microsoft Defender for Containers** — Runtime threat detection and vulnerability scanning
- **Container Insights** — Full observability with Log Analytics
- **Network Policy (Azure NPM)** — Micro-segmentation for pod-to-pod traffic
- **Image Cleaner** — Automatic removal of stale/vulnerable images from nodes
- **Run Command disabled** — Prevents `az aks command invoke` access
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

### Destroy / cleanup

This demo uses Terraform safety rails (`lifecycle.prevent_destroy`) to protect:

- the AKS cluster
- the jumpbox public IP

So a plain `terraform destroy` will fail unless you **temporarily remove** the `prevent_destroy = true` lines in:

- `infra/terraform/modules/aks/main.tf`
- `infra/terraform/modules/jumpbox/main.tf`

Then run `terraform destroy`, and re-enable `prevent_destroy` afterwards.

## GitHub Actions CI/CD

The repo includes workflows for infrastructure and workload deployments, using **Azure OIDC** (no stored credentials).

| Workflow | Trigger | Action |
|----------|---------|--------|
| `infra-terraform.yml` | PR to main/develop | Validate + Plan (comments on PR) |
| `infra-terraform.yml` | Push to main | Apply |

### Setup: Azure OIDC for GitHub Actions

1. **Create an App Registration:**

```zsh
az ad app create --display-name "github-actions-aks-demo"

# Note the appId (client ID)
APP_ID=$(az ad app list --display-name "github-actions-aks-demo" --query "[0].appId" -o tsv)
```

2. **Create a Service Principal and assign least-privilege roles:**

```zsh
az ad sp create --id $APP_ID

# Set these to match your naming convention (see variables.tf)
PREFIX="aks-demo01"        # var.prefix
ENVIRONMENT="dev"          # var.environment
LOCATION_CODE="weu"        # westeurope → weu, northeurope → neu

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
INFRA_RG="${PREFIX}-${ENVIRONMENT}-${LOCATION_CODE}-rg"
TFSTATE_RG="${PREFIX}-${LOCATION_CODE}-tfstate-rg"

# Contributor on the infra resource group (create/update/delete resources)
az role assignment create \
  --assignee $APP_ID \
  --role "Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$INFRA_RG"

# Storage Blob Data Contributor on tfstate RG (read/write state blobs)
az role assignment create \
  --assignee $APP_ID \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$TFSTATE_RG"
```

> **Note:** For initial bootstrap (creating new RGs), you may need temporary broader scope,
> then reduce to RG-scoped after resources exist.

3. **Add Federated Credential for GitHub:**

```zsh
# For the 'main' branch
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "gha-aks-demo-project-main",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:enrico2828/aks-demo-project:ref:refs/heads/main",
  "audiences": ["api://AzureADTokenExchange"]
}'

# For pull requests
az ad app federated-credential create --id $APP_ID --parameters '{
  "name": "gha-aks-demo-project-pr",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:enrico2828/aks-demo-project:pull_request",
  "audiences": ["api://AzureADTokenExchange"]
}'
```

4. **Add GitHub Repository Secrets:**

For multi-environment setups, prefer **Environment secrets** (recommended) so you can protect applies with approvals.

Create an environment named **dev** (default in this repo) and optionally **production**:

- **Settings → Environments → New environment → `dev`**
- **Settings → Environments → New environment → `production`** (optional)

Then add secrets under each environment:

| Secret | Value |
|--------|-------|
| `AZURE_CLIENT_ID` | `$APP_ID` (from step 1) |
| `AZURE_TENANT_ID` | `az account show --query tenantId -o tsv` |
| `AZURE_SUBSCRIPTION_ID` | `az account show --query id -o tsv` |

> **Tip:** You can also store these as **Repository secrets** (Settings → Secrets and variables → Actions) if you only use one environment.

5. **(Optional) Protect the `production` environment:**

Go to **Settings → Environments → New environment → "production"** and add required reviewers for manual approval before apply.

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

## Configuration reference

Key variables (see `variables.tf` for full list):

### General

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `westeurope` | Azure region |
| `prefix` | `aks-demo01` | Resource naming prefix |
| `environment` | `dev` | Environment tag |
| `aks_admin_group_object_ids` | — | Entra ID group(s) for cluster admin |
| `jumpbox_bootstrap_tools` | `false` | Install az/kubectl/kubelogin via cloud-init |
| `jumpbox_kubectl_version` | (latest) | Pin kubectl version (e.g., `v1.29.15`) |
| `jumpbox_kubelogin_version` | (latest) | Pin kubelogin version (e.g., `0.2.14`) |

### Security hardening

| Variable | Default | Description |
|----------|---------|-------------|
| `enable_azure_policy` | `true` | Enable Azure Policy for Kubernetes |
| `azure_policy_level` | `baseline` | `baseline` (PSS baseline) or `restricted` (PSS restricted) |
| `azure_policy_effect` | `deny` | `audit` for visibility, `deny` for enforcement |
| `enable_defender_for_containers` | `true` | Enable Microsoft Defender for Containers |
| `aks_network_policy` | `azure` | Network policy: `azure`, `calico`, or `null` |
| `image_cleaner_enabled` | `true` | Remove stale/vulnerable images from nodes |
| `aks_run_command_enabled` | `false` | Allow `az aks command invoke` |
| `key_vault_secrets_provider_enabled` | `false` | Enable Key Vault CSI driver |
| `log_analytics_retention_days` | `30` | Log retention in days (minimum) |

### Safety rails

Some resources are protected with Terraform `lifecycle.prevent_destroy` to reduce the risk of accidental deletion:

- AKS cluster (`modules/aks/main.tf`)
- Jumpbox public IP (`modules/jumpbox/main.tf`)

### How to destroy when really needed
To destroy intentionally:

1. Temporarily remove (or set to `false`) the `prevent_destroy = true` lines in the two files above.
2. Run `terraform destroy` (or `terraform destroy -target=module.aks` / `-target=module.jumpbox`).
3. Re-enable `prevent_destroy = true` afterwards.

## Architecture notes

### Network

- VNet: `10.10.0.0/16`
- AKS subnet: `10.10.0.0/22` (1024 addresses)
- Jumpbox subnet: `10.10.5.0/27` (32 addresses)
- Private endpoints subnet: `10.10.4.0/24`
- Pod CIDR (overlay): `192.168.0.0/16`
- Service CIDR: `10.20.0.0/16`

### AKS configuration

- **Network plugin**: Azure CNI Overlay
- **Network policy**: Azure NPM (default) — enables pod-to-pod micro-segmentation
- **Private cluster**: Yes (API server not internet-accessible)
- **Local accounts**: Disabled (Entra ID only)
- **OIDC issuer**: Enabled (for Workload Identity)
- **System node pool**: 1 node, `Standard_D2s_v5`, critical addons only
- **Azure Policy**: Gatekeeper-based pod security enforcement
- **Image Cleaner**: Automatic cleanup of stale images (48h interval)
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
4. `kubectl` commands use `kubelogin` to obtain tokens from the `az` session
5. AKS validates the token and checks Azure RBAC role assignments

## Next steps

Planned additions:

- ACR (Azure Container Registry) with private endpoint
- Key Vault integration with CSI driver
- GitHub Actions (OIDC-based CI/CD)
- Application workloads with Workload Identity
- Network policies for workload segmentation
- Alerting (Action Group + metric/log alerts for node/pod health)

## Out of scope

The following are useful for production but excluded from this demo due to cost:

- **Azure Managed Grafana + Prometheus** — Full observability stack (~€150/month for Grafana). Container Insights provides sufficient monitoring for demo purposes.
- **Azure Front Door / Application Gateway** — Ingress with WAF.
- **Azure Firewall** — Egress filtering (requires dedicated subnet + ~€900/month).
