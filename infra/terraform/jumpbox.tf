module "jumpbox" {
  source = "./modules/jumpbox"

  name_prefix         = local.name_prefix
  location            = var.location
  resource_group_name = data.azurerm_resource_group.rg.name
  tags                = local.common_tags

  subnet_id = module.network.subnet_ids["jumpbox"]

  # Public IP is optional. If enabled, SSH is restricted to var.jumpbox_allowed_ssh_cidrs.
  assign_public_ip = var.jumpbox_assign_public_ip

  admin_username = "azureuser"

  # Configure this locally via infra/terraform/jumpbox.auto.tfvars (not committed).
  ssh_public_key = var.jumpbox_ssh_public_key

  vm_size = var.jumpbox_vm_size

  image_publisher = var.jumpbox_image_publisher
  image_offer     = var.jumpbox_image_offer
  image_sku       = var.jumpbox_image_sku
  image_version   = var.jumpbox_image_version

  allowed_ssh_cidrs = var.jumpbox_allowed_ssh_cidrs

  cloud_init = var.jumpbox_bootstrap_tools ? templatefile("${path.module}/modules/jumpbox/cloud-init.yaml.tftpl", {
    # If null, cloud-init will omit the version flag and let `az aks install-cli` install "latest".
    kubectl_version = (
      var.jumpbox_kubectl_version != null ? var.jumpbox_kubectl_version : (
        var.aks_kubernetes_version != null ? "v${var.aks_kubernetes_version}" : ""
      )
    )
    kubelogin_version = var.jumpbox_kubelogin_version != null ? var.jumpbox_kubelogin_version : ""
  }) : null
}
