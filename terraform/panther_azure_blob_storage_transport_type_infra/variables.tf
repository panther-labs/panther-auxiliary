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
  default     = "pantherstorageaccount"
}

variable "container_name" {
  description = "Name of the blob container"
  type        = string
  default     = "panther-logs"
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