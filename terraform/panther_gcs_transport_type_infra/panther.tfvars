# Basic Info
project_id = "project-id" # ID (name) of your GCP project
gcp_region = "gcp-region" # GCP Region that your infrastructure will live
gcp_zone   = "gcp-zone"   # GCP Availability Zone that your infrastructure will live

# Panther will pull data from this GCS bucket by way of Pub/Sub Notifications
# If your bucket already exists you would need to either import the resource in this terraform
# project or remove the `resource` definition from the `main.tf` file.
bucket_name         = "bucket-name"
topic_name          = "topic-name"
subscription_id     = "subscription-id"
gcs_bucket_location = "gcs-bucket-location"

# Prefixes that notifications will be setup for. Data will need to be added within thoses prefixes
# You need to edit the following to include your subdirectories.
# Use `*` for all subdirectories
gcs_bucket_prefixes = ["logs/", "audit-logs"]

# Panther needs a Service account to be able to authenticate and pull data from the topic
panther_service_account_id           = "panther-service-account-id"
panther_service_account_display_name = "panther-service-account-display-name"