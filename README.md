# Azure-native AKS Demo (Terraform)

This repository is a hands-on AKS platform buildout intended for architecture practice (AZ-305 style) and for demonstrating a pragmatic, enterprise-leaning approach.

The project is implemented incrementally. The **current state** delivers:

- Terraform remote state in Azure Storage (bootstrapped via ARM)
- A foundation resource group
- A VNet with right-sized subnets
- A Linux jumpbox VM for administration tasks
  - SSH keys only (no password authentication)
  - Optional public IP for demo convenience
  - SSH restricted to an explicit allow-list of CIDRs

## Repo layout

- `infra/bootstrap/arm/`  ARM template used to provision Terraform remote state infrastructure
- `infra/terraform/`  Terraform root module (network + jumpbox)

## Prerequisites

- Azure CLI authenticated to the correct subscription
- Terraform >= 1.5 (see `infra/terraform/versions.tf`)

## Remote state bootstrap (ARM)

Terraform state is stored remotely in Azure Storage. The storage account + container are created via ARM.

1) Choose a resource group name for Terraform state, for example `aks-demo01-weu-tfstate-rg`.

2) Choose a globally unique storage account name (324 chars; lowercase letters and numbers only) and update:

- `infra/bootstrap/arm/tfstate.parameters.json`

3) Deploy the ARM template:

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

> The state storage account uses **Standard_LRS** to keep costs down.

## Terraform backend configuration

Backend settings live in `infra/terraform/backend.hcl`. Update it to match your state RG/storage/container/key and then initialize:

```zsh
cd infra/terraform
terraform init -backend-config=backend.hcl
```

## Local configuration (recommended)

This deployment uses local-only `*.auto.tfvars` files for developer-specific settings.
These files are not committed (see `.gitignore`).

### Generate an SSH key (recommended)

Create a dedicated keypair for this project.

```zsh
# Note: Azure VM provisioning expects an RSA public key here (ed25519 can be rejected).
ssh-keygen -t rsa -b 4096 -a 64 -C "aks-demo-jumpbox" -f ~/.ssh/aks-demo-jumpbox-rsa

# Print the public key (paste the full line into jumpbox.auto.tfvars)
cat ~/.ssh/aks-demo-jumpbox-rsa.pub
```

### Configure Terraform (jumpbox settings)

```zsh
cd infra/terraform
cp jumpbox.auto.tfvars.example jumpbox.auto.tfvars
```

Edit `infra/terraform/jumpbox.auto.tfvars` and set at minimum:

- `jumpbox_ssh_public_key`  OpenSSH-format public key string

To enable SSH access from your laptop:

- `jumpbox_assign_public_ip = true`
- `jumpbox_allowed_ssh_cidrs = ["<your-public-ip>/32"]`

## Deploy / update the foundation

```zsh
cd infra/terraform
terraform fmt -recursive
terraform validate
terraform apply
```

## Connect to the jumpbox

After `terraform apply`, retrieve the public IP (if enabled):

```zsh
cd infra/terraform
terraform output jumpbox_public_ip
```

On macOS, SSH can offer many keys from your agent/keychain and the VM may disconnect with **"Too many authentication failures"**.
Use `IdentitiesOnly` to ensure only the intended key is offered.

One-off connection:

```zsh
ssh -o IdentitiesOnly=yes -i ~/.ssh/aks-demo-jumpbox-rsa azureuser@<jumpbox_public_ip>
```

Optional `~/.ssh/config` entry:

```sshconfig
Host aks-demo-jumpbox
  HostName <jumpbox_public_ip>
  User azureuser
  IdentityFile ~/.ssh/aks-demo-jumpbox-rsa
  IdentitiesOnly yes
```

Then connect with:

```zsh
ssh aks-demo-jumpbox
```

## Outputs

Terraform exports a few useful values (see `infra/terraform/outputs.tf`), including:

- `jumpbox_private_ip`
- `jumpbox_public_ip` (if enabled)
- `subnet_ids`

## Defaults

Terraform defaults (see `infra/terraform/variables.tf`):

- `location`: `westeurope`
- `prefix`: `aks-demo01`
- `environment`: `dev`

## Next steps

Planned additions (not implemented yet):

- AKS deployment (cluster, node pools, identities)
- ACR + Key Vault + Log Analytics
- GitHub Actions (Terraform and application delivery using OIDC)
