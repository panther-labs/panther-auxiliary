# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



variable "aws_partition" {
  type        = string
  description = "AWS partition where this template / Panther is deployed"
  default     = "aws"
}

variable "master_account_id" {
  type        = string
  description = "Panther AWS account ID"
}

variable "master_account_region" {
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
