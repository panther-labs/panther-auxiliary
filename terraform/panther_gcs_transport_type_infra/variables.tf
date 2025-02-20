# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

variable "project_id" {
  type        = string
  description = "GCP Project name"
}

variable "bucket_name" {
  type        = string
  description = "Panther will read GCS Objects from this Bucket"
}

variable "topic_name" {
  type        = string
  description = "Pub/Sub topic name"
}

variable "subscription_id" {
  type        = string
  description = "Pub/Sub subscription id"
}

variable "gcp_region" {
  type        = string
  description = "GCP Region"
}

variable "gcp_zone" {
  type        = string
  description = "GCP Zone"
}

# Possible locations listed here: https://cloud.google.com/storage/docs/locations
variable "gcs_bucket_location" {
  type        = string
  description = "GCS Bucket location"
}

variable "panther_service_account_id" {
  type        = string
  description = "Panther Service Account ID"
}

variable "panther_service_account_display_name" {
  type        = string
  description = "Panther Service Account Display Name"
}

# Specifies a prefix path filter for this notification config.
# Cloud Storage only sends notifications for objects in this bucket whose names begin with the specified prefix.
variable "gcs_bucket_prefixes" {
  type        = set(string)
  default     = [""]
  description = "GCS Bucket prefixes"
}

variable "authentication_method" {
  type        = string
  description = "Authentication method for GCP"
  default     = "service_account"

  validation {
    condition     = contains(["service_account", "workload_identity_federation"], var.authentication_method)
    error_message = "Invalid authentication method. Must be one of 'service_account' or 'workload_identity_federation'"
  }
}

variable "panther_workload_identity_pool_id" {
  type        = string
  description = "Panther Workload Identity Pool ID"
  default     = ""

  validation {
    condition     = var.authentication_method != "workload_identity_federation" || var.panther_workload_identity_pool_id != ""
    error_message = "Panther Workload Identity Pool ID is required when using workload_identity_federation"
  }
}

variable "panther_workload_identity_pool_provider_id" {
  type        = string
  description = "Panther Workload Identity Pool Provider ID"
  default     = ""

  validation {
    condition     = var.authentication_method != "workload_identity_federation" || var.panther_workload_identity_pool_provider_id != ""
    error_message = "Panther Workload Identity Pool Provider ID is required when using workload_identity_federation"
  }
}

variable "panther_aws_account_id" {
  type        = string
  description = "Panther AWS Account ID"
  default     = ""

  validation {
    condition     = var.authentication_method != "workload_identity_federation" || var.panther_aws_account_id != ""
    error_message = "Panther AWS Account ID is required when using workload_identity_federation"
  }
}
