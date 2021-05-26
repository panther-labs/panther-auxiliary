# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

resource "random_uuid" "subscription_name" {
}

resource "aws_iam_role" "cloudwatch_firehose_role" {
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "logs.${var.aws_region}.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })

  inline_policy {
    name = "cloudwatch_firehose_policy"
    policy = jsonencode({
      "Version" : "2012-10-17"
      "Statement" : [
        {
          "Action" : ["firehose:*"]
          "Effect" : "Allow"
          "Resource" : ["arn:${var.aws_partition}:firehose:${var.aws_region}:${var.aws_account_id}:*"]
        }
      ]
    })
  }
}

resource "aws_iam_role" "firehose_s3_role" {
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
    name = "firehose_s3_policy"
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
          "Resource" : [
            aws_s3_bucket.firehose_bucket.arn,
            "${aws_s3_bucket.firehose_bucket.arn}/*"
          ]
        }
      ]
    })
  }
}

resource "aws_s3_bucket" "firehose_bucket" {
  acl = "private"
  versioning {
    enabled = true
  }
  lifecycle_rule {
    id      = "${var.expiration_in_days}DayExpiration"
    enabled = true
    expiration {
      days = var.expiration_in_days
    }
    noncurrent_version_expiration {
      days = var.expiration_in_days
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_kinesis_firehose_delivery_stream" "panther_firehose" {
  name        = "panther_firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.firehose_bucket.arn
    buffer_size        = 128 # Maximum
    buffer_interval    = var.buffer_interval_in_seconds
    compression_format = "GZIP"
    prefix             = "PantherCloudWatchStream/" # Magic S3 prefix which tells Panther that a special data transformation needs to be done prior to parsing.
    role_arn           = aws_iam_role.firehose_s3_role.arn
  }
}

resource "aws_cloudwatch_log_subscription_filter" "cloudwatch_subscription_filter" {
  name            = "panther-subscription-${random_uuid.subscription_name.result}"
  destination_arn = aws_kinesis_firehose_delivery_stream.panther_firehose.arn
  filter_pattern  = var.subscription_filter_pattern
  log_group_name  = var.cloudwatch_log_group_name
  role_arn        = aws_iam_role.cloudwatch_firehose_role.arn
}
