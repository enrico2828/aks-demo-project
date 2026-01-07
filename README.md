# Azure-native AKS Reference Deployment (Terraform + GitHub Actions)

This repository contains a reference implementation for deploying an Azure Kubernetes Service (AKS) platform using **Terraform** and deploying workloads using **GitHub Actions** authenticated to Azure via **OIDC federation** (no long-lived credentials).

The design emphasizes:

- **Security**: private control plane, Azure AD RBAC, Key Vault integration
- **Operational readiness**: Azure Monitor / Log Analytics
- **Governance-friendly** patterns (role assignments, centralized state)
- **Cost awareness**: small node pools and conservative retention settings

## Architecture (target)

### Platform components

- Resource group(s)
- Virtual Network + subnets
  - AKS subnet
  - Private Endpoints subnet
- AKS
  - Private API server (Private Link)
  - Azure AD RBAC
  - Workload Identity
  - Add-ons: Azure Monitor / Container Insights, Key Vault CSI Driver
- Azure Container Registry (ACR)
- Azure Key Vault
- Log Analytics Workspace

### Delivery

- GitHub Actions
  - Infrastructure workflow: Terraform plan/apply
  - Application workflow: build image → push to ACR → deploy to AKS (Helm)
- Authentication: GitHub OIDC → Azure federated credential

## Repository layout

- `infra/bootstrap/arm/` — ARM template used to provision Terraform remote state infrastructure
- `infra/terraform/` — Terraform root module (platform infrastructure)

## Usage

### Validate Terraform configuration

```zsh
cd infra/terraform
terraform init
terraform fmt -recursive
terraform validate
```

### Bootstrap remote state using ARM

1) Choose a resource group name for state, for example `aks-demo01-weu-tfstate-rg`.

2) Choose a globally unique storage account name (3–24 chars; lowercase letters and numbers only) and update `infra/bootstrap/arm/tfstate.parameters.json` (parameters: `storageAccountName`, `terraformStateContainerName`).

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

> The state storage account is deployed with **Standard_LRS** to keep this reference deployment cost-efficient. 

### Configure Terraform remote state (azurerm backend)

After the ARM deployment succeeds, initialize the Terraform backend using `infra/terraform/backend.hcl`:

```zsh
cd infra/terraform
terraform init -backend-config=backend.hcl
```

The backend configuration references the storage account created by the ARM template, the state container, and an environment-specific state key (for example `dev.tfstate`).

## Configuration defaults

Terraform defaults (see `infra/terraform/variables.tf`):

- `location`: `westeurope`
- `prefix`: `aks-demo01`
- `environment`: `dev`

## Roadmap

Planned additions:

- Remote state backend configuration (`backend "azurerm"`) and state migration
- Network module (VNet/subnets, private DNS where required)
- Jumpbox module (temporary admin access to private AKS)
- AKS module (private cluster, workload identity, add-ons)
- ACR + Key Vault + Log Analytics
- GitHub Actions workflows (Terraform + app delivery)
