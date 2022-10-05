# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

variable "project_id" {
  type        = string
  description = "GCP Project name"
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

variable "panther_service_account_id" {
  type        = string
  description = "Panther Service Account ID"
}

variable "panther_service_account_display_name" {
  type        = string
  description = "Panther Service Account Display Name"
}