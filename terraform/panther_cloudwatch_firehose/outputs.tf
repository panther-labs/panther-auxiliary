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
