# NOTE: this resource must be applied in the Panther master account, not in a satellite account,
# because subscriptions originating in a queue owner's account do not require confirmation.
# Subscriptions in the CloudFormation template version of this log_processing Terraform module
# are applied in the opposite manner (in satellite accounts) because Panther is configured to
# auto-confirm subscription requests originating from CloudFormation.

# Each satellite account requires its own topic subscription resource. In Terraform, this can be 
# accomplished for multiple accounts using a for_each expression.

resource "aws_sns_topic_subscription" "panther_log_processing" {
  for_each = toset(var.satellite_accounts)

  endpoint             = "arn:${var.aws_partition}:sqs:${var.panther_region}:${var.master_account_id}:panther-input-data-notifications-queue"
  protocol             = "sqs"
  raw_message_delivery = false
  topic_arn            = "arn:${var.aws_partition}:sns:${var.satellite_account_region}:${each.key}:panther-notifications-topic"
}

variable "satellite_accounts" {
  description = "The account numbers of satellite accounts that will have the Log Processing Notifications module applied to them"
  type        = list(string)
}
