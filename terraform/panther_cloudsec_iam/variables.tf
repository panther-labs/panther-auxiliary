# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.



variable "aws_partition" {
  type        = string
  description = "AWS partition where this template / Panther is deployed"
  default     = "aws"
}

variable "panther_aws_account_id" {
  type        = string
  description = "Panther AWS account ID"
}

variable "panther_aws_account_region" {
  type        = string
  description = "Panther AWS account region"
}

variable "include_audit_role" {
  type    = bool
  default = true
}

variable "include_stack_set_execution_role" {
  type    = bool
  default = true
}
