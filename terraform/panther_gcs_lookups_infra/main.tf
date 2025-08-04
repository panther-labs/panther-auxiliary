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
  panther_identity = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.pool.name}/attribute.account/${var.panther_aws_account_id}"
}

data "google_project" "google_project" {
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
  uniform_bucket_level_access = true
}

# IAM Policies

# Workload Identity Pool
resource "google_iam_workload_identity_pool" "pool" {
  workload_identity_pool_id = var.panther_workload_identity_pool_id
}

# Provider
resource "google_iam_workload_identity_pool_provider" "provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.pool.workload_identity_pool_id
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

# Storage Viewer
resource "google_storage_bucket_iam_member" "binding" {
  bucket = google_storage_bucket.gcs-bucket.name
  role   = "roles/storage.objectViewer"
  member = local.panther_identity
}

output "project_number" {
  value = data.google_project.google_project.number
}

output "pool_id" {
  value = google_iam_workload_identity_pool.pool.workload_identity_pool_id
}

output "provider_id" {
  value = google_iam_workload_identity_pool_provider.provider.workload_identity_pool_provider_id
}
