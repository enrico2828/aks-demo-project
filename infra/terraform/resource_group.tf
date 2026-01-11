# Resource group is created by ARM bootstrap (infra/bootstrap/arm/bootstrap.json)
# Using data source ensures Terraform only manages resources INSIDE the RG,
# enabling true least-privilege (Contributor scoped to RG, not subscription).

data "azurerm_resource_group" "rg" {
  name = "${local.name_prefix}-rg"
}
