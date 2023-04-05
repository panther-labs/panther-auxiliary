# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

# Create a resource group
resource "azurerm_resource_group" "panther_azure_resource_group" {
  name     = var.resource_group_name
  location = var.azure_region
}

resource "azurerm_storage_account" "panther_azure_storage_account" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.panther_azure_resource_group.name
  location                 = azurerm_resource_group.panther_azure_resource_group.location
  account_tier             = "Standard"
  account_replication_type = var.storage_account_redundancy
}

resource "azurerm_storage_container" "panther_azure_storage_container" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.panther_azure_storage_account.name
  container_access_type = "private"
}


resource "azurerm_storage_queue" "panther_azure_storage_queue" {
  name                 = "${var.container_name}-queue"
  storage_account_name = azurerm_storage_account.panther_azure_storage_account.name
}


resource "azurerm_eventgrid_system_topic" "panther_azure_storage_eventgrid_topic" {
  name                   = "${var.container_name}-topic"
  resource_group_name    = azurerm_resource_group.panther_azure_resource_group.name
  location               = azurerm_resource_group.panther_azure_resource_group.location
  source_arm_resource_id = azurerm_storage_account.panther_azure_storage_account.id
  topic_type             = "Microsoft.Storage.StorageAccounts"
}


resource "azurerm_eventgrid_system_topic_event_subscription" "panther_azure_storage_eventgrid_topic_subscription" {
  name                 = "${var.container_name}-topic-subscription"
  system_topic         = azurerm_eventgrid_system_topic.panther_azure_storage_eventgrid_topic.name
  resource_group_name  = azurerm_resource_group.panther_azure_resource_group.name
  included_event_types = ["Microsoft.Storage.BlobCreated"]
  storage_queue_endpoint {
    storage_account_id = azurerm_storage_account.panther_azure_storage_account.id
    queue_name         = azurerm_storage_queue.panther_azure_storage_queue.name
  }

  subject_filter {
    subject_begins_with = "/blobServices/default/containers/${var.container_name}/"
  }
}


data "azurerm_subscription" "primary" {}

data "azurerm_client_config" "azure_client" {}
data "azuread_client_config" "azuread_client" {}

resource "azuread_application" "panther_azure_application" {
  display_name = var.application_name
}

resource "azuread_application_password" "panther_app_secret" {
  application_object_id = azuread_application.panther_azure_application.object_id
  display_name          = "panther"
}

output "client_id" {
  value = azuread_application.panther_azure_application.application_id
}

output "secret" {
  value     = azuread_application_password.panther_app_secret.value
  sensitive = true
}

resource "azuread_service_principal" "panther_azure_application_principal" {
  application_id               = azuread_application.panther_azure_application.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.azuread_client.object_id]
}

resource "azurerm_role_assignment" "panther_azure_role_assignment_blob_read" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/blobServices/default/containers/${var.container_name}"
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azuread_service_principal.panther_azure_application_principal.id
  depends_on = [
    azurerm_resource_group.panther_azure_resource_group,
    azurerm_storage_account.panther_azure_storage_account
  ]
}

resource "azurerm_role_assignment" "panther_azure_role_assignment_queue" {
  scope                = "${data.azurerm_subscription.primary.id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Storage/storageAccounts/${var.storage_account_name}/queueServices/default/queues/${var.container_name}-queue"
  role_definition_name = "Storage Queue Data Message Processor"
  principal_id         = azuread_service_principal.panther_azure_application_principal.id
  depends_on = [
    azurerm_resource_group.panther_azure_resource_group,
    azurerm_storage_account.panther_azure_storage_account
  ]
}
