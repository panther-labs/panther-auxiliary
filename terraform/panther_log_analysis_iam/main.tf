# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.




#####
# IAM roles for log ingestion from an S3 bucket

resource "aws_iam_role" "log_processing" {
  name                 = "PantherLogProcessingRole-${var.role_suffix}"
  max_session_duration = 3600 # 1 hour

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : "arn:${var.aws_partition}:iam::${var.master_account_id}:root"
        }
        Action : "sts:AssumeRole",
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      }
    ]
  })

  tags = {
    Application = "Panther"
  }
}

resource "aws_iam_role_policy" "log_processing" {
  name = "ReadData"
  role = aws_iam_role.log_processing.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "s3:GetBucketLocation",
        Resource : "arn:aws:s3:::${var.s3_bucket_name}"
      },
      {
        Effect : "Allow",
        Action : "s3:GetObject",
        Resource : "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_prefix}*"
      },
      {
        Effect : "Allow",
        Action : [
          "kms:Decrypt",
          "kms:DescribeKey"
        ],
        Resource : var.kms_key_arn
      }
    ]
  })
}
