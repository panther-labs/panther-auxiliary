variable "aws_account_id" {
  type        = string
  description = "The account id where the template is being deployed"
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

variable "expiration_in_days" {
  type        = number
  default     = 7
  description = "Indicates the number of days after creation when objects are deleted from Amazon S3."
}