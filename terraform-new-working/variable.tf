variable "name" {
  description = "Application name"
  type        = string
  default     = "prashanth-group101"
}

variable "location" {
  description = "Azure location where resources are to be created"
  type        = string
  default     = "North Europe"
}

variable "vault_version" {
  description = "Vault version to run"
  type        = string
  default     = "1.2.0"
}

variable "resource_group_name" {
  description = "Azure resource group where resources are to be created"
  type        = string
  default     = "maersktraining"
}

variable "key_vault_tier" {
  description = "Azure KeyVault service tier (Standard or Premium)"
  type        = string
  default     = "Standard"
}

variable "key_name" {
  description = "Azure Key Vault key name"
  default     = "vault-key"
}

variable "service_plan_tier" {
  description = "Azure App Service Plan tier (Free, Basic, Standard, PremiumV2)"
  type        = string
  default     = "Free"
}

variable "service_plan_size" {
  description = "Azure App Service Plan size"
  type        = string
  default     = "F1"
}

variable "enable_continuous_deployment" {
  description = "Enable continuous deployment of new container tags (e.g. latest)"
  type        = bool
  default     = false
}