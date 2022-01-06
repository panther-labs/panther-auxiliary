# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



variable "aws_partition" {
  type    = string
  default = "aws"
}

variable "sns_topic_name" {
  type        = string
  description = "The name of the SNS topic"
  default     = "panther-notifications-topic"
}

variable "master_account_id" {
  type        = string
  description = "The AWS account where you have deployed Panther"
}

variable "panther_region" {
  type        = string
  description = "The AWS region where you have deployed Panther"
}

variable "satellite_account_region" {
  type        = string
  description = "Account which Panther is pulling or receiving log data from"
}

# existing role (not managed by this template) that will be used to manage
# the KMS CMK used by the SNS topic
# Unless you use a dedicated key management role, this will be the role
# you use in the AWS console or the role used in your template deployment
# pipeline 
variable "sns_log_processing_cmk_mgmt_role_arn" {
  type        = string
  description = "ARN of IAM role used to manage the KMS CMK for the SNS topic"
}
