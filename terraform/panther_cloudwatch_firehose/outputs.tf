# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

output "firehose_bucket_name" {
  value       = aws_s3_bucket.firehose_bucket.bucket
  description = "S3 Bucket containing the data"
}

output "role_arn" {
  value       = aws_iam_role.log_processing_role.arn
  description = "The ARN of the log processing role that Panther will use to read S3 objects."
}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}
