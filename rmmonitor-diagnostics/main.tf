terraform {
  required_version = ">= 0.12.6"
  required_providers {
    azurerm = "~> 1.36.0"
  }
}

locals {
  diag_resource_list = split("/", var.destination)

  log_analytics_id   = contains(local.diag_resource_list, "microsoft.operationalinsights") ? var.destination : null
  storage_account_id = contains(local.diag_resource_list, "Microsoft.Storage") ? var.destination : null
  event_hub_auth_id  = contains(local.diag_resource_list, "Microsoft.EventHub") ? var.destination : null

  targets_map = { for target in var.target_ids : target => true }
}

resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = local.targets_map

  name                           = "${var.name}-diag"
  target_resource_id             = each.key
  log_analytics_workspace_id     = local.log_analytics_id
  eventhub_authorization_rule_id = local.event_hub_auth_id
  eventhub_name                  = local.event_hub_auth_id != null ? var.eventhub_name : null
  storage_account_id             = local.storage_account_id

  dynamic "log" {
    for_each = var.logs
    content {
      category = log.value

      retention_policy {
        enabled = false
      }
    }
  }

  dynamic "metric" {
    for_each = var.metrics
    content {
      category = metric.value

      retention_policy {
        enabled = false
      }
    }
  }
}