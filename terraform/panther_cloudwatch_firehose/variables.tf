# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

variable "aws_account_id" {
  type        = string
  description = "The account id where the template is being deployed"
}

variable "aws_partition" {
  type    = string
  default = "aws"
}

variable "aws_region" {
  type        = string
  description = "The region where the template is being deployed"
}

variable "buffer_interval_in_seconds" {
  type        = number
  default     = 300
  description = "Buffer incoming data for the specified period of time, in seconds, before delivering it to the destination. The default value is 300."
}

variable "cloudwatch_log_group_name" {
  type        = string
  description = "The Log group name that will be ingested by panther."
}

variable "expiration_in_days" {
  type        = number
  default     = 7
  description = "Indicates the number of days after creation when objects are deleted from Amazon S3."
}

variable "subscription_filter_pattern" {
  type        = string
  default     = " "
  description = "(Optional) The default pattern \" \" will return all events, You can specify a more specific filter pattern here."
}