 terraform {
  required_version = ">= 0.11" 
 backend "azurerm" {
  storage_account_name = "Prashanth-RG"
    container_name       = "teststoragetf"
    key                  = "terraform.tfstate"
	access_key  ="0V85JNhyK+laYGbYIkURdC40nY02bMtpkPihEw+QTZxt2P3MIV6GIN1NKbzwjcd33Ue5EF87YJZx6cf0rnP0dg=="
	}
	}
resource "azurerm_resource_group" "dev" {
  name     = "Prashanth-RG"
  location = "North Europe"
}

resource "azurerm_app_service_plan" "dev" {
  name                = "appserviceplan"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"

  sku {
    tier = "Free"
    size = "F1"
  }
}

resource "azurerm_app_service" "dev" {
  name                = "__appservicename__"
  location            = "${azurerm_resource_group.dev.location}"
  resource_group_name = "${azurerm_resource_group.dev.name}"
  app_service_plan_id = "${azurerm_app_service_plan.dev.id}"

}

# Create a Service Principal for Vault
resource "azuread_application" "vault" {
  name                       = "${var.name}-sp"
  available_to_other_tenants = false
}

resource "azuread_service_principal" "vault" {
  application_id = "${azuread_application.vault.application_id}"
}

resource "random_string" "vault_sp_password" {
  length  = 36
  special = false
}

resource "azuread_service_principal_password" "vault" {
  service_principal_id = "${azuread_service_principal.vault.id}"
  value                = "${random_string.vault_sp_password.result}"
  end_date             = "2099-01-01T00:00:00Z"
}

resource "random_id" "vault" {
  byte_length = 4
}

# Create an Azure Key Vault for Vault
resource "azurerm_key_vault" "vault" {
  name                        = "${var.name}-${lower(random_id.vault.hex)}-kv"
  location                    = "${var.location}"
  resource_group_name         = "${var.resource_group_name}"
  enabled_for_deployment      = true
  enabled_for_disk_encryption = true
  tenant_id                   = "${data.azurerm_client_config.current.tenant_id}"
  sku_name                    = "${lower(var.key_vault_tier)}"
}

resource "azurerm_key_vault_access_policy" "vault_sp" {
  key_vault_id = "${azurerm_key_vault.vault.id}"
  tenant_id    = "${data.azurerm_client_config.current.tenant_id}"
  object_id    = "${azuread_service_principal.vault.object_id}"

  key_permissions = [
    "get",
    "list",
    "create",
    "delete",
    "update",
    "wrapKey",
    "unwrapKey",
  ]
}

resource "azurerm_key_vault_access_policy" "azure_account" {
  key_vault_id = "${azurerm_key_vault.vault.id}"
  tenant_id    = "${data.azurerm_client_config.current.tenant_id}"
  object_id    = "${data.azurerm_client_config.current.object_id}"

  key_permissions = [
    "get",
    "list",
    "create",
  ]
}

resource "azurerm_key_vault_key" "vault" {
  name         = "${var.key_name}"
  key_vault_id = "${azurerm_key_vault.vault.id}"
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [azurerm_key_vault_access_policy.azure_account]
}

# Create an Azure Storage Account for Vault
resource "azurerm_storage_account" "vault" {
  name                     = "${replace(replace(var.name, "_", ""), "-", "")}${lower(random_id.vault.hex)}"
  location                 = "${var.location}"
  resource_group_name      = "${var.resource_group_name}"
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "vault" {
  name                  = "vault"
  storage_account_name  = "${azurerm_storage_account.vault.name}"
  container_access_type = "private"
}

# Deploy Vault on Azure App Service
resource "azurerm_app_service_plan" "vault" {
  name                = "${var.name}-plan"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "${var.service_plan_tier}"
    size = "${var.service_plan_size}"
  }

}

resource "azurerm_app_service" "vault" {
  name                = "${var.name}-${lower(random_id.vault.hex)}-as"
  location            = "${var.location}"
  resource_group_name = "${var.resource_group_name}"
  app_service_plan_id = "${azurerm_app_service_plan.vault.id}"
  https_only          = true

  site_config {
    app_command_line          = "server"
    linux_fx_version          = "DOCKER|vault:${var.vault_version}"
    use_32_bit_worker_process = true
    ftps_state                = "Disabled"
  }

  app_settings = {
    "SKIP_SETCAP"                         = "true"
    "WEBSITES_PORT"                       = "8200"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io"
    "DOCKER_ENABLE_CI"                    = "${var.enable_continuous_deployment}"
    "VAULT_LOCAL_CONFIG"                  = "${local.vault_config}"
  }
}

output "vault_addr" {
  value = <<VAULT
    Connect to Vault by setting the VAULT_ADDR
    $ export VAULT_ADDR=https://${azurerm_app_service.vault.default_site_hostname}
VAULT

}