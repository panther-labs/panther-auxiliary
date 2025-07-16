variable "aws_partition" {
  type        = string
  default     = "aws"
  description = "AWS partition of the account running the Panther backend e.g aws, aws-cn, or aws-us-gov"
}

variable "aws_account_id" {
  type        = string
  description = "The AWS account ID where the template is being deployed"
}

variable "panther_aws_account_id" {
  type        = string
  description = "The AWS account ID of your Panther instance"
}

variable "role_suffix" {
  type        = string
  description = "A unique identifier that will be used as the IAM role suffix"
}

variable "s3_bucket_name" {
  type        = string
  description = "The S3 Bucket name to onboard"
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the KMS key if your data is encrypted using KMS-SSE"
  default     = ""
}

variable "managed_bucket_notifications_enabled" {
  type        = bool
  description = "Allow Panther to configure bucket SNS notifications"
  default     = true
}
