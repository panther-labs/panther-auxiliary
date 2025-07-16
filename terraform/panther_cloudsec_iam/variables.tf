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
