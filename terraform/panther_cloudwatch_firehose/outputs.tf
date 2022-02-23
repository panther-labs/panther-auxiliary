# Copyright (C) 2022 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

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
