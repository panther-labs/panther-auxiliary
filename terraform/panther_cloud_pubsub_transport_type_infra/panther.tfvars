# Basic Info
project_id      = "project-id"      # ID (name) of your GCP project
topic_name      = "topic-name"      # Topic name to be created. Data will need to be published here
subscription_id = "subscription-id" # Name for the subscription Panther will use to consume from the topic
gcp_region      = "gcp-region"      # Region of the topic and the subscription

# Panther needs a Service account to be able to authenticate and pull data from the topic
panther_service_account_id           = "panther-service-account-id"
panther_service_account_display_name = "panther-service-account-display-name"

# Configures authentication method for GCP; one of "service_account" or "workload_identity_federation"
authentication_method = "service_account"

# Required when using Workload Identity Federation
panther_workload_identity_pool_id          = "panther-workload-identity-pool"
panther_workload_identity_pool_provider_id = "panther-workload-identity-pool-provider"
panther_aws_account_id                     = "000000000000"
