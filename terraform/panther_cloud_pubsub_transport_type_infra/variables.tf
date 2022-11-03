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