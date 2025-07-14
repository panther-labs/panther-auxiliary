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

variable "panther_workload_identity_pool_id" {
  type        = string
  description = "Panther Workload Identity Pool ID"
}

variable "panther_workload_identity_pool_provider_id" {
  type        = string
  description = "Panther Workload Identity Pool Provider ID"
}

variable "panther_aws_account_id" {
  type        = string
  description = "Panther AWS Account ID"
}
