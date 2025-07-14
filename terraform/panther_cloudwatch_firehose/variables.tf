# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.


variable "panther_aws_account_id" {
  type        = string
  description = "The AWS account ID of the account running Panther"
}

variable "stack_name" {
  type        = string
  description = "The stack name, is recommended to use the name of the CloudWatch source"
}

variable "buffering_size" {
  type        = number
  default     = 128 # Maximum
  description = " Buffer incoming data to the specified size, in MBs, before delivering it to the destination"
}

variable "buffer_interval_in_seconds" {
  type        = number
  default     = 300 # 5min
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. The default value is 300"
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "The Log group name that will be ingested by panther"
}

variable "expiration_in_days" {
  type        = number
  default     = 7
  description = "Indicates the number of days after creation when objects are deleted from Amazon S3"
}

variable "subscription_filter_pattern" {
  type        = string
  default     = " "
  description = "(Optional) The default pattern \" \" will return all events, You can specify a more specific filter pattern here"
}

variable "managed_bucket_notifications_enabled" {
  type        = bool
  description = "Allowing Panther to configure bucket notifications"
  default     = true
}
