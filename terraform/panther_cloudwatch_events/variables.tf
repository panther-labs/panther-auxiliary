variable "aws_partition" {
  type        = string
  description = "AWS partition of the account running the Panther backend"
  default     = "aws"
}

variable "panther_region" {
  type        = string
  description = "AWS region where you have deployed Panther"
}

variable "satellite_account_region" {
  type        = string
  description = "AWS Region of satellite account"
}

variable "master_account_id" {
  type        = string
  description = "AWS account ID of the account running Panther"
}

# topic name is hardcoded in Panther infra; see IAM policies for panther-aws-events-queue
# SQS queue and panther-aws-event-processor Lambda function in master account
variable "sns_topic_name" {
  type        = string
  description = "The name of the SNS topic"
  default     = "panther-cloudwatch-events-topic"
}

# existing role (not managed by this template) that will be used to manage
# the KMS CMK used by the SNS topic
# Unless you use a dedicated key management role, this will be the role
# you use in the AWS console or the role used in your template deployment
# pipeline 
variable "sns_events_cmk_mgmt_role_arn" {
  type        = string
  description = "ARN of IAM role used to manage the KMS CMK for the SNS topic"
}
