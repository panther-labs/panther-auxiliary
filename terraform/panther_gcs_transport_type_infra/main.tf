# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

provider "google" {
  # Authentication to GCP can happen with multiple ways.
  # If you're running from your workstation, we recommend using ADCs with the gcloud CLI tool.
  # `gcloud auth application-default login`
  # Check the provider information: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference

  project = var.project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

locals {
  workload_identity_federation_enabled = var.authentication_method == "workload_identity_federation"
  service_account_identity = (
    local.workload_identity_federation_enabled
    ? null
    : "serviceAccount:${google_service_account.panther_service_account[0].email}"
  )
  workload_identity_federation_identity = (
    local.workload_identity_federation_enabled
    ? "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool[0].name}/attribute.account/${var.panther_aws_account_id}"
    : null
  )
  panther_identity = (
    local.workload_identity_federation_enabled
    ? local.workload_identity_federation_identity
    : local.service_account_identity
  )
}

# Obtain and save GCS built-in service account in order to use it for the notifications below
data "google_storage_project_service_account" "gcs_account" {
}

data "google_project" "google_project" {
  count = local.workload_identity_federation_enabled ? 1 : 0
}

# Create a bucket
# If the bucket already exists, 
# remove the below resource google_storage_bucket 
# and replace the google_storage_bucket.gcs-bucket.name with your bucket input (e.g var.bucket_name)
resource "google_storage_bucket" "gcs-bucket" {
  name          = var.bucket_name
  location      = var.gcs_bucket_location
  force_destroy = false
  # Uniform bucket-level access must be enabled to grant Workforce Identity Federation or Workload Identity Federation entities
  # access to Cloud Storage resources (https://cloud.google.com/storage/docs/uniform-bucket-level-access#should-you-use)
  uniform_bucket_level_access = local.workload_identity_federation_enabled
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
# A bucket can have up to 100 total notification configurations.
resource "google_storage_notification" "notification" {
  for_each           = var.gcs_bucket_prefixes
  bucket             = google_storage_bucket.gcs-bucket.name
  payload_format     = "JSON_API_V1"
  topic              = google_pubsub_topic.topic.name
  event_types        = ["OBJECT_FINALIZE"]
  depends_on         = [google_pubsub_topic_iam_binding.binding]
  object_name_prefix = each.value
}
# Create the service account that will be used by panther
resource "google_service_account" "panther_service_account" {
  count = local.workload_identity_federation_enabled ? 0 : 1

  account_id   = var.panther_service_account_id
  display_name = var.panther_service_account_display_name
}

# IAM Policies

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  count = local.workload_identity_federation_enabled ? 1 : 0

  workload_identity_pool_id = var.panther_workload_identity_pool_id
}

# Provider
resource "google_iam_workload_identity_pool_provider" "provider" {
  count = local.workload_identity_federation_enabled ? 1 : 0

  workload_identity_pool_id          = google_iam_workload_identity_pool.pool[0].workload_identity_pool_id
  workload_identity_pool_provider_id = var.panther_workload_identity_pool_provider_id
  attribute_condition                = "attribute.account==\"${var.panther_aws_account_id}\""
  attribute_mapping = {
    # AWS assertion looks like this:
    # {
    #   "Account": "123456789012"
    #   "Arn": "arn:aws:sts::123456789012:assumed-role/panther-<function_name>-function-1234567890123456789012345/panther-<function_name>"
    #   "UserId": "ARO123EXAMPLE123:panther-<function_name>"
    # }
    # where <function_name> is the name of the function e.g. cloud-puller
    "google.subject"    = "assertion.arn"
    "attribute.arn"     = "assertion.arn"
    "attribute.account" = "assertion.account"
    "attribute.user_id" = "assertion.userid"
    "attribute.role"    = "assertion.arn.extract('assumed-role/{role}/')"
  }
  aws {
    account_id = var.panther_aws_account_id
  }
}

# Storage Viewer
resource "google_storage_bucket_iam_member" "binding" {
  bucket = google_storage_bucket.gcs-bucket.name
  role   = "roles/storage.objectViewer"
  member = local.panther_identity
}

# Pub/Sub Viewer
resource "google_pubsub_subscription_iam_member" "viewer" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.viewer"
  member       = local.panther_identity
}

# Pub/Sub Subscriber
resource "google_pubsub_subscription_iam_member" "subscriber" {
  subscription = google_pubsub_subscription.subscription.name
  role         = "roles/pubsub.subscriber"
  member       = local.panther_identity
}

# Monitoring Viewer for the entire project
resource "google_project_iam_member" "project" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = local.panther_identity
}

output "service_account_email" {
  value       = local.workload_identity_federation_enabled ? null : google_service_account.panther_service_account[0].email
  description = "Service account email"
  sensitive   = false
}

output "project_number" {
  value = local.workload_identity_federation_enabled ? data.google_project.google_project[0].number : null
}

output "pool_id" {
  value = local.workload_identity_federation_enabled ? google_iam_workload_identity_pool.pool[0].workload_identity_pool_id : null
}

output "provider_id" {
  value = local.workload_identity_federation_enabled ? google_iam_workload_identity_pool_provider.provider[0].workload_identity_pool_provider_id : null
}
