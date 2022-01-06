# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.




#####
# Sets up an SNS topic.

# This topic is used to notify the Panther master account whenever new data is written to the
# LogProcessing bucket.
resource "aws_sns_topic" "log_processing" {
  name = var.sns_topic_name

  # Note: the AWS-managed CMK for the SNS service, "alias/aws/sns",
  # cannot be used because Panther subscribes an encrypted SQS queue
  # (panther-input-data-notifications-queue) to this topic
  # see https://docs.aws.amazon.com/sns/latest/dg/sns-enable-encryption-for-topic-sqs-queue-subscriptions.html
  kms_master_key_id = "alias/panther-log-processing"
}

resource "aws_sns_topic_policy" "policy" {
  arn = aws_sns_topic.log_processing.arn

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      # Reference: https://amzn.to/2ouFmhK
      {
        Sid : "AllowS3EventNotifications",
        Effect : "Allow",
        Principal : {
          Service : "s3.amazonaws.com"
        },
        Action : "sns:Publish",
        Resource : aws_sns_topic.log_processing.arn
      },
      {
        Sid : "AllowCloudTrailNotification",
        Effect : "Allow",
        Principal : {
          Service : "cloudtrail.amazonaws.com"
        },
        Action : "sns:Publish",
        Resource : aws_sns_topic.log_processing.arn
      },
      {
        Sid : "AllowSubscriptionToPanther",
        Effect : "Allow",
        Principal : {
          AWS : "arn:${var.aws_partition}:iam::${var.master_account_id}:root"
        },
        Action : "sns:Subscribe",
        Resource : aws_sns_topic.log_processing.arn
      }
    ]
  })
}

# customer-managed CMK
# Note: the key policy for programmatically created customer-managed
# CMKs is automatically configured to allow :root (every identity) 
# in the satellite account to perform kms:* actions on the key if a 
# key policy is not specified. 
resource "aws_kms_key" "panther_log_processing" {
  description = "The Panther log processing customer-managed CMK"
  policy      = data.aws_iam_policy_document.panther_log_processing_cmk.json
}

resource "aws_kms_alias" "panther_log_processing" {
  name          = "alias/panther-log-processing"
  target_key_id = aws_kms_key.panther_log_processing.key_id
}

# the customer-managed CMK key policy (not an IAM policy despite 
# Terraform data source name)
data "aws_iam_policy_document" "panther_log_processing_cmk" {
  statement {
    sid = "S3CloudTrailSNSPublish"
    actions = [
      "kms:GenerateDataKey",
      "kms:Decrypt"
    ]
    resources = ["*"]
    effect    = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "s3.amazonaws.com",
        "cloudtrail.amazonaws.com"
      ]
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
      identifiers = [var.sns_log_processing_cmk_mgmt_role_arn]
    }
  }
}
