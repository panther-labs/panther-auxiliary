# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



variable "aws_account_id" {
  type        = string
  description = "AWS account where this template will be deployed"
}

variable "aws_region" {
  type        = string
  description = "AWS region where this template will be deployed"
}

variable "s3_notifications_topic" {
  type        = string
  description = "SNS topic arn to send S3 notifications for pulling data"
}
