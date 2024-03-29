# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

variable "resource_group_name" {
  type        = string
  description = "All created resources will be grouped under this Resource Group"
  default     = "panther-rg"
}

variable "azure_region" {
  type        = string
  description = "Azure Region"
}

variable "storage_account_name" {
  type        = string
  description = "Name of the created Storage Account"
}

variable "application_name" {
  type        = string
  description = "Name of the Azure AD application to be created"
  default     = "panther-log-puller"
}

variable "storage_account_redundancy" {
  type        = string
  description = "Storage Account Redundancy Setting, see https://learn.microsoft.com/en-us/azure/storage/common/storage-redundancy"
  default     = "GRS"
}

variable "blob_prefix" {
  type        = string
  description = "prefix for filtering blobs"
  default     = ""
}