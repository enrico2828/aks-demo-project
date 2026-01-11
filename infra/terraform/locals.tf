locals {
  # Short region codes keep resource names readable and within Azure limits.
  region_code = {
    westeurope  = "weu"
    northeurope = "neu"
  }

  location_code = lookup(local.region_code, var.location, var.location)

  name_prefix = "${var.prefix}-${var.environment}-${local.location_code}"

  common_tags = merge(var.tags, {
    environment = var.environment
  })
}
