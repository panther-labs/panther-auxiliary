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
  zone    = var.gcp_zone
}

# Obtain and save GCS built-in service account in order to use it for the notifications below
data "google_storage_project_service_account" "gcs_account" {
}

# Create a bucket
resource "google_storage_bucket" "gcs-bucket" {
  name          = var.bucket_name
  location      = var.gcs_bucket_location
  force_destroy = false
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

  # Maximum expiration policy. 7 days. (default)
  # https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/pubsub_subscription#expiration_policy
  expiration_policy {
    ttl = "604800s"
  }

  # Retry policies set the minimum and/or maximum delay between consecutive deliveries of a given message
  retry_policy {
    minimum_backoff = "10s" # default
  }

  enable_message_ordering = false # default
}

# Adding a required Role in the built-in GCS Service account
resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.topic.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

# Bucket notifications for new files
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.gcs-bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.topic.name
  event_types    = ["OBJECT_FINALIZE"]
  depends_on     = [google_pubsub_topic_iam_binding.binding]
}

# Create the service account that will be used by panther
resource "google_service_account" "panther_service_account" {
  account_id   = var.panther_service_account_id
  display_name = var.panther_service_account_display_name
}

# IAM Policies

# Storage Viewer
resource "google_storage_bucket_iam_member" "binding" {
  bucket = google_storage_bucket.gcs-bucket.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${google_service_account.panther_service_account.email}"
}

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

# Monitoring Viewer for the entire project
resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.panther_service_account.email}"
}

output "service_account_email" {
  value       = google_service_account.panther_service_account.email
  description = "Service account email"
  sensitive   = false
}