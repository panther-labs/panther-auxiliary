# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



####
# This template configures Panther's real-time CloudWatch Event collection process.
# It works by creating CloudWatch Event rules which feed to Panther's SQS Queue proxied by
# a local SNS topic in each region.

resource "aws_sns_topic" "panther_events" {
  name = var.sns_topic_name

  # Note: the AWS-managed CMK for the SNS service, "alias/aws/sns",
  # cannot be used because Panther subscribes an encrypted SQS queue
  # (panther-aws-events-queue) to this topic
  # see https://docs.aws.amazon.com/sns/latest/dg/sns-enable-encryption-for-topic-sqs-queue-subscriptions.html
  kms_master_key_id = "alias/panther-events"
}

resource "aws_sns_topic_policy" "panther_events" {
  arn = aws_sns_topic.panther_events.arn

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "CloudWatchEventsPublish",
        Effect : "Allow",
        Principal : {
          Service : "events.amazonaws.com"
        }
        Action : "sns:Publish",
        Resource : aws_sns_topic.panther_events.arn
      },
      {
        Sid : "CrossAccountSubscription",
        Effect : "Allow",
        Principal : {
          AWS : "arn:${var.aws_partition}:iam::${var.master_account_id}:root"
        }
        Action : "sns:Subscribe",
        Resource : aws_sns_topic.panther_events.arn
      }
    ]
  })
}

# Note: the key policy for programmatically created customer-managed
# CMKs is automatically configured to allow :root (every identity) 
# in the satellite account to perform kms:* actions on the key if a 
# key policy is not specified. 
resource "aws_kms_key" "panther_events" {
  description = "The Panther CloudWatch events customer-managed CMK"
  policy      = data.aws_iam_policy_document.panther_events_cmk.json
}

resource "aws_kms_alias" "panther_events" {
  name          = "alias/panther-events"
  target_key_id = aws_kms_key.panther_events.key_id
}

# Note: not an IAM policy despite the Terraform data source name
data "aws_iam_policy_document" "panther_events_cmk" {
  statement {
    sid = "EventBridgeSNSPublish"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = ["*"]
    effect    = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }

  statement {
    sid = "KeyManagement"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    resources = ["*"]
    effect    = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.sns_events_cmk_mgmt_role_arn]
    }
  }
}

resource "aws_cloudwatch_event_rule" "cloudtrail" {
  name        = "panther-cloud-security-real-time-events"
  description = "Collect CloudTrail API calls"
  is_enabled  = true

  event_pattern = jsonencode({
    detail-type : [
      "AWS API Call via CloudTrail"
    ]
  })
}

resource "aws_cloudwatch_event_target" "cloudtrail" {
  rule      = aws_cloudwatch_event_rule.cloudtrail.name
  target_id = "panther-collect-cloudtrail-events"
  arn       = aws_sns_topic.panther_events.arn
}
