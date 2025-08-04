provider "google" {
  # Authentication to GCP can happen with multiple ways.
  # If you're running from your workstation, we recommend using ADCs with the gcloud CLI tool.
  # `gcloud auth application-default login`
  # Check the provider information: https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/provider_reference

  project = var.project_id
  region  = var.gcp_region
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

data "google_project" "project" {
  count = local.workload_identity_federation_enabled ? 1 : 0
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
  count = local.workload_identity_federation_enabled ? 0 : 1

  account_id   = var.panther_service_account_id
  display_name = var.panther_service_account_display_name
}

### ~~~ IAM Policies ~~~

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
    # AWS assertion looks like this(from https://docs.aws.amazon.com/STS/latest/APIReference/API_GetCallerIdentity.html "Example 2 - Called by user created with AssumeRole"):
    # assertion.arn: arn:aws:sts::123456789012:assumed-role/my-role-name/my-role-session-name
    # assertion.userid: ARO123EXAMPLE123:my-role-session-name
    # assertion.account: 123456789012
    "google.subject"    = "assertion.arn.extract('arn:aws:sts::{account_id}:')+\":\"+assertion.arn.extract('assumed-role/{role_and_session}').extract('/{session}')"
    "attribute.account" = "assertion.account"
  }
  aws {
    account_id = var.panther_aws_account_id
  }
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

output "service_account_email" {
  value       = local.workload_identity_federation_enabled ? null : google_service_account.panther_service_account[0].email
  description = "Service account email"
  sensitive   = false
}

output "project_number" {
  value = local.workload_identity_federation_enabled ? data.google_project.project[0].number : null
}

output "pool_id" {
  value = local.workload_identity_federation_enabled ? google_iam_workload_identity_pool.pool[0].workload_identity_pool_id : null
}

output "provider_id" {
  value = local.workload_identity_federation_enabled ? google_iam_workload_identity_pool_provider.provider[0].workload_identity_pool_provider_id : null
}
