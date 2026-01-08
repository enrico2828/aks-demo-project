# Azure-native AKS Demo (Terraform)

An enterprise-style AKS platform for architecture practice (AZ-305) and demonstration purposes.

## What's deployed

| Resource | Description |
|----------|-------------|
| **Resource Group** | `aks-demo01-dev-weu-rg` |
| **VNet** | `aks-demo01-dev-weu-vnet` with subnets for AKS, jumpbox, and private endpoints |
| **AKS Cluster** | Private cluster with Azure CNI Overlay, Entra ID integration, Azure RBAC for Kubernetes |
| **Jumpbox VM** | Linux VM for cluster administration (SSH + optional public IP) |
| **Terraform State** | Remote state in Azure Storage |

### Security posture

- **Private AKS** — API server is not exposed to the internet
- **Entra ID authentication** — no local Kubernetes accounts; `--admin` credential disabled
- **Azure RBAC for Kubernetes** — authorization via Azure role assignments
- **Jumpbox hardened** — SSH keys only, explicit CIDR allow-list, no password auth

## Repository layout

```
infra/
├── bootstrap/arm/          # ARM template for Terraform state storage
└── terraform/
    ├── modules/
    │   ├── aks/            # AKS cluster module
    │   ├── jumpbox/        # Jumpbox VM module
    │   └── network/        # VNet + subnets module
    ├── *.tf                # Root module
    └── backend.hcl         # Backend configuration
```

## Prerequisites

- Azure CLI (`az`) authenticated to the target subscription
- Terraform >= 1.5
- An Entra ID security group for AKS administrators

## Quick start

### 1. Bootstrap Terraform state storage

```zsh
az login

az group create \
  --name aks-demo01-weu-tfstate-rg \
  --location westeurope

az deployment group create \
  --resource-group aks-demo01-weu-tfstate-rg \
  --template-file infra/bootstrap/arm/tfstate.json \
  --parameters infra/bootstrap/arm/tfstate.parameters.json
```

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

## Configuration reference

Key variables (see `variables.tf` for full list):

| Variable | Default | Description |
|----------|---------|-------------|
| `location` | `westeurope` | Azure region |
| `prefix` | `aks-demo01` | Resource naming prefix |
| `environment` | `dev` | Environment tag |
| `aks_admin_group_object_ids` | — | Entra ID group(s) for cluster admin |
| `jumpbox_bootstrap_tools` | `false` | Install az/kubectl/kubelogin via cloud-init |
| `jumpbox_kubectl_version` | (latest) | Pin kubectl version |
| `jumpbox_kubelogin_version` | (latest) | Pin kubelogin version |

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
- **Private cluster**: Yes (API server not internet-accessible)
- **Local accounts**: Disabled (Entra ID only)
- **OIDC issuer**: Enabled (for Workload Identity)
- **System node pool**: 1 node, `Standard_D2s_v5`, critical addons only

### Authentication flow

1. User SSHs to jumpbox
2. `az login` authenticates to Entra ID
3. `az aks get-credentials` fetches kubeconfig (configured for Entra auth)
4. `kubectl` commands use `kubelogin` to obtain tokens from the `az` session
5. AKS validates the token and checks Azure RBAC role assignments

## Next steps

Planned additions:

- ACR (Azure Container Registry)
- Key Vault for secrets
- Log Analytics / Container Insights
- GitHub Actions (OIDC-based CI/CD)
- Application workloads with Workload Identity
