# IAM roles for log ingestion from an S3 bucket
resource "aws_iam_role" "log_processing_role" {
  name = "PantherLogProcessingRole-${var.role_suffix}"

  # Policy that grants an entity permission to assume the role.
  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Effect : "Allow",
        Principal : {
          AWS : "arn:${var.aws_partition}:iam::${var.panther_aws_account_id}:root"
        }
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      }
    ]
  })

  tags = {
    "panther:app" = "panther"
  }
}


# Provides an IAM role inline policy for reading s3 Data
resource "aws_iam_role_policy" "read_data_policy" {
  name = "ReadData"
  role = aws_iam_role.log_processing_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ],
        Resource : "arn:${var.aws_partition}:s3:::${var.s3_bucket_name}"
      },
      {
        Effect : "Allow",
        Action : "s3:GetObject",
        Resource : "arn:${var.aws_partition}:s3:::${var.s3_bucket_name}/*"
    }, ]
  })
}

# Provides an ARN that decrypts ciphertext that was encrypted by a KMS key
resource "aws_iam_role_policy" "kms_decryption" {
  count = var.kms_key_arn != "" ? 1 : 0
  name  = "kmsDecryption"
  role  = aws_iam_role.log_processing_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
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


# Provides an IAM role inline policy for managing panther notification topic
resource "aws_iam_role_policy" "manage_panther_topic_policy" {
  count = var.managed_bucket_notifications_enabled ? 1 : 0
  name  = "ManagePantherTopic"
  role  = aws_iam_role.log_processing_role.id
  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "sns:*",
        Resource : "arn:${var.aws_partition}:sns:*:${var.aws_account_id}:panther-notifications-topic"
      }
    ]
  })
}

# Provides an IAM role inline policy for reading and adding notification configuration of a bucket
resource "aws_iam_role_policy" "managed_bucket_notifications_policy" {
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
        Resource : "arn:${var.aws_partition}:s3:::${var.s3_bucket_name}"
      }
    ]
  })
}
