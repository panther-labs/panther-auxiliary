resource "aws_kinesis_firehose_delivery_stream" "fluentd_firehose" {
  name        = "fluentd_firehose"
  destination = "extended_s3"

  extended_s3_configuration {
    bucket_arn         = aws_s3_bucket.firehose_bucket.arn
    buffer_size        = 128 # Maximum
    buffer_interval    = var.buffer_interval_in_seconds
    compression_format = "GZIP"
    role_arn           = aws_iam_role.firehose_service_role.arn
    prefix             = var.s3_prefix
  }
}

resource "aws_iam_role" "firehose_service_role" {
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Condition : {
          StringEquals : { "sts:ExternalId" : var.aws_account_id }
        }
        Principal : {
          Service : "firehose.amazonaws.com"
        },
        Effect : "Allow"
      }
    ]
  })
}

resource "aws_iam_policy" "fluentd_firehose_managed_policy" {
  description = "Firehose permissions to write to data bucket"
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Sid : "AllowS3Delivery",
        Effect : "Allow",
        Action : [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource : [
          aws_s3_bucket.firehose_bucket.arn,
          "${aws_s3_bucket.firehose_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "fluentd" {
  policy_arn = aws_iam_policy.fluentd_firehose_managed_policy.arn
  role       = aws_iam_role.firehose_service_role.id
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

resource "aws_s3_bucket_policy" "firehose_bucket" {
  bucket     = aws_s3_bucket.firehose_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.firehose_bucket]

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Deny",
        Principal : "*",
        Action : "s3:GetObject",
        Resource : "${aws_s3_bucket.firehose_bucket.arn}/*",
        Condition : {
          Bool : { "aws:SecureTransport" : false }
        }
      }
    ]
  })
}

resource "aws_s3_bucket_public_access_block" "firehose_bucket" {
  bucket                  = aws_s3_bucket.firehose_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### EC2 Instance Profile ###
resource "aws_iam_instance_profile" "fluentd_firehose" {
  name = "FluentdFirehoseWriteOnly-${var.aws_region}"
  role = aws_iam_role.fluentd_firehose_instance_profile.id
}

resource "aws_iam_role" "fluentd_firehose_instance_profile" {
  name = "fluentdFirehoseAssumeRole-${var.aws_region}"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "ec2.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fluentd_firehose_instance_profile" {
  name = "AssumeFirehoseRole"
  role = aws_iam_role.fluentd_firehose_instance_profile.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "sts:AssumeRole",
        Resource : aws_iam_role.fluentd_firehose_write_only.arn
      }
    ]
  })
}

resource "aws_iam_role" "fluentd_firehose_write_only" {
  name = "FluentdFirehoseWriteOnly-${var.aws_region}"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : "arn:aws:iam::${var.aws_account_id}:root"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "fluentd_firehose_write_only" {
  name = "FirehosePutRecords"
  role = aws_iam_role.fluentd_firehose_write_only.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "firehose:PutRecord",
          "firehose:PutRecordBatch"
        ]
        Resource : aws_kinesis_firehose_delivery_stream.fluentd_firehose.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_read_only" {
  role       = aws_iam_role.fluentd_firehose_write_only.id
  policy_arn = "arn:aws:iam::aws:policy/AmazonKinesisFirehoseReadOnlyAccess"
}
