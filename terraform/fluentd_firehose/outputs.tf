output "InstanceProfileName" {
  value = aws_iam_instance_profile.fluentd_firehose.name
}
output "FirehoseName" {
  value = aws_kinesis_firehose_delivery_stream.fluentd_firehose.name
}

output "FirehoseSendDataRoleArn" {
  value = aws_iam_role.fluentd_firehose_write_only.arn
}

output "S3Bucket" {
  value = aws_s3_bucket.firehose_bucket.id
}