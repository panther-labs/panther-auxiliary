# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.



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
