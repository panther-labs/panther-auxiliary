# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



output "sns_topic_arn" {
  # The ARN of the SNS Topic that will be notifying Panther of new data.
  value = aws_sns_topic.log_processing.arn
}
