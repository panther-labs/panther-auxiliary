output "role_arn" {
  value       = aws_iam_role.log_processing_role.arn
  description = "The ARN of the log processing role that Panther will use to read S3 objects."
}
