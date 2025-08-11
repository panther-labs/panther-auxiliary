output "sns_topic_arn" {
  # The ARN of the SNS Topic that will be notifying Panther of new data.
  value = aws_sns_topic.log_processing.arn
}
