# Basic Info
project_id = "project-id" # ID (name) of your GCP project
gcp_region = "gcp-region" # GCP Region that your infrastructure will live
gcp_zone   = "gcp-zone"   # GCP Availability Zone that your infrastructure will live

# If your bucket already exists you would need to either import the resource in this terraform
# project or remove the `resource` definition from the `main.tf` file.
bucket_name         = "bucket-name"
gcs_bucket_location = "gcs-bucket-location"

# Required when using Workload Identity Federation
panther_workload_identity_pool_id          = "panther-workload-identity-pool"
panther_workload_identity_pool_provider_id = "panther-workload-identity-pool-provider"
panther_aws_account_id                     = "000000000000"
