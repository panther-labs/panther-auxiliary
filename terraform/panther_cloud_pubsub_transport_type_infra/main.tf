# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

provider "google" {
  # Authentication to GCP can happen with multiple ways.
  # If you're running from your workstation, we recommend using ADCs with the gcloud CLI tool.
  # `gcloud auth application-default login`
  # Check the provider information: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference

  project = var.project_id
  region  = var.gcp_region
}

# Create a topic
resource "google_pubsub_topic" "topic" {
  name = var.topic_name

  message_retention_duration = "604800s" # 7 days (maximum)
  message_storage_policy {
    allowed_persistence_regions = [var.gcp_region]
  }
}

# Create a subscription for the topic
resource "google_pubsub_subscription" "subscription" {
  name  = var.subscription_id
  topic = google_pubsub_topic.topic.name

  message_retention_duration = "604800s" # 7 days. (default)
  retain_acked_messages      = false     # Remove acknowledged messages (default)

  ack_deadline_seconds = 600 # maximum

  expiration_policy {
    ttl = ""
  }

  # Retry policies set the minimum and/or maximum delay between consecutive deliveries of a given message
  retry_policy {
    minimum_backoff = "10s" # default
  }

  enable_message_ordering = false # default
}

# Create the service account that will be used by panther
resource "google_service_account" "panther_service_account" {
  account_id   = var.panther_service_account_id
  display_name = var.panther_service_account_display_name
}

### ~~~ IAM Policies ~~~

# Pub/Sub Viewer
resource "google_pubsub_subscription_iam_member" "viewer" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.viewer"
  member       = "serviceAccount:${google_service_account.panther_service_account.email}"
}

# Pub/Sub Subscriber
resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${google_service_account.panther_service_account.email}"
}

output "service_account_email" {
  value       = google_service_account.panther_service_account.email
  description = "Service account email"
  sensitive   = false
}
