# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.


# Infrastructure to deliver CloudWatch log group to Panther.

#  obtain the name of the AWS region configured on the provider.
data "aws_region" "current" {}
# lookup information about the current AWS partition.
data "aws_partition" "current" {}
# get the access to the effective Account ID in which Terraform is authorized.
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "log_processing_role" {
  # The role to be assumed by Panther log processor to process incoming data and optionally set up and check notifications
  # NOTE: needs to be kept in sync with panther-log-analysis-iam.yml
  name = "PantherLogProcessingRole-${var.stack_name}"

  # Policy that grants an entity permission to assume the role.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          AWS : "arn:${data.aws_partition.current.partition}:iam::${var.panther_aws_account_id}:root"
        }
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      }
    ]
  })

  inline_policy {
    name = "ReadData"
    policy = jsonencode({
      Version : "2012-10-17",
      Statement : [
        {
          Effect : "Allow",
          Action : [
            "s3:GetBucketLocation",
            "s3:ListBucket",
          ],
          Resource : aws_s3_bucket.firehose_bucket.arn
        },
        {
          Effect : "Allow",
          Action : "s3:GetObject",
          Resource : [aws_s3_bucket.firehose_bucket.arn, "${aws_s3_bucket.firehose_bucket.arn}/*"]
      }, ]
    })
  }

  tags = {
    Application = "Panther"
  }
}



resource "aws_iam_role" "cloudwatch_firehose_role" {
  name = "${var.stack_name}-CloudwatchFirehoseRole"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "logs.${data.aws_region.current.name}.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })

  inline_policy {
    name = "panther-cloudwatch-firehose-policy"
    policy = jsonencode({
      "Version" : "2012-10-17"
      "Statement" : [
        {
          "Action" : "firehose:*"
          "Effect" : "Allow"
          "Resource" : aws_kinesis_firehose_delivery_stream.panther_firehose.arn
        }
      ]
    })
  }
}

resource "aws_iam_role" "firehose_s3_role" {
  name = "${var.stack_name}-FirehoseS3Role"

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "firehose.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
  inline_policy {
    name = "panther-firehose-s3-policy"
    policy = jsonencode({
      "Version" : "2012-10-17"
      "Statement" : [
        {
          "Action" : [
            "s3:AbortMultipartUpload",
            "s3:GetBucketLocation",
            "s3:GetObject",
            "s3:ListBucket",
            "s3:ListBucketMultipartUploads",
            "s3:PutObject"
          ]
          "Effect" : "Allow"
          "Resource" : [aws_s3_bucket.firehose_bucket.arn, "${aws_s3_bucket.firehose_bucket.arn}/*"]

        }
      ]
    })
  }
}

# Provides an IAM role inline policy for managing panther notification topic
resource "aws_iam_role_policy" "manage_panther_topic_policy" {
  # NOTE: needs to be kept in sync with panther-log-analysis-iam.yml
  # An IAM policy to allow LogProcessingRole to set up and manage an SNS topic for panther notifications
  count = var.managed_bucket_notifications_enabled ? 1 : 0
  name  = "ManagePantherTopic"
  role  = aws_iam_role.log_processing_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "sns:*",
        Resource : "arn:${data.aws_partition.current.partition}:sns:*:${data.aws_caller_identity.current.account_id}:panther-notifications-topic"
      }
    ]
  })
}

# Provides an IAM role inline policy for reading and adding notification configuration of a bucket
resource "aws_iam_role_policy" "managed_bucket_notifications_policy" {
  # NOTE: needs to be kept in sync with panther-log-analysis-iam.yml
  # An IAM policy to allow LogProcessingRole to set up and check bucket notifications for the FirehoseBucket
  count = var.managed_bucket_notifications_enabled ? 1 : 0
  name  = "GetPutBucketNotifications"
  role  = aws_iam_role.log_processing_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "s3:GetBucketNotification",
          "s3:PutBucketNotification",
        ],
        Resource : aws_s3_bucket.firehose_bucket.arn
      }
    ]
  })
}

resource "aws_s3_bucket" "firehose_bucket" {
  bucket = "${var.stack_name}-firehosebucket"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  rule {
    id     = "WeekExpiration"
    status = "Enabled"
    expiration {
      days = var.expiration_in_days
    }
    noncurrent_version_expiration {
      noncurrent_days = var.expiration_in_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "firehose_bucket" {
  bucket = aws_s3_bucket.firehose_bucket.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_kinesis_firehose_delivery_stream" "panther_firehose" {
  name        = "${var.stack_name}-PantherFirehose"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.firehose_bucket.arn
    buffering_size     = var.buffering_size
    buffering_interval = var.buffer_interval_in_seconds
    role_arn           = aws_iam_role.firehose_s3_role.arn
  }
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  name            = "${var.stack_name}-CloudwatchSubscriptionFilter"
  destination_arn = aws_kinesis_firehose_delivery_stream.panther_firehose.arn
  filter_pattern  = var.subscription_filter_pattern
  log_group_name  = var.cloudwatch_log_group_name
  role_arn        = aws_iam_role.cloudwatch_firehose_role.arn
}
