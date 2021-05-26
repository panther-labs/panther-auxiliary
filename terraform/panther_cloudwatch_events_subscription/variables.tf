# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



variable "aws_partition" {
  type    = string
  default = "aws"
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
  description = "Account from which Panther is receiving event data"
}
