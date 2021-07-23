# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.

resource "aws_iam_role" "support" {
  name        = var.support_role_name
  description = "IAM role for troubleshooting Panther"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : var.assume_role_principal
        },
        Action : "sts:AssumeRole",
        Condition : {
          Bool : {
            "aws:MultiFactorAuthPresent" : true,
            "aws:SecureTransport" : true
          },
          NumericLessThan : {
            "aws:MultiFactorAuthAge" : var.max_session_duration_sec
          }
        }
      }
    ]
  })

  tags = {
    Application = "Panther"
  }
}

resource "aws_iam_policy" "support" {
  name = "PantherSupport"

  # DO NOT EDIT - policy is automatically copied from CloudFormation by 'mage fmt'
  policy = <<EOT
{
  "Statement": [
    {
      "Action": [
        "acm:ListCertificates",
        "acm:DescribeCertificate",
        "ce:GetCostAndUsage",
        "ce:GetDimensionValues",
        "dynamodb:ListTables",
        "dynamodb:DescribeLimits",
        "dynamodb:DescribeTable",
        "dynamodb:DescribeTimeToLive",
        "ecr:DescribeImages",
        "ecr:DescribeRepositories",
        "ecs:DescribeClusters",
        "ecs:DescribeContainerInstances",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTaskSets",
        "ecs:DescribeTasks",
        "ecs:ListAccountSettings",
        "ecs:ListAttributes",
        "ecs:ListClusters",
        "ecs:ListContainerInstances",
        "ecs:ListServices",
        "ecs:ListTaskDefinitions",
        "ecs:ListTasks",
        "elasticfilesystem:DescribeFileSystems",
        "elasticloadbalancing:DescribeLoadBalancers",
        "firehose:DescribeDeliveryStream",
        "firehose:List*",
        "glue:BatchGet*",
        "glue:Get*",
        "health:*",
        "events:Describe*",
        "events:List*",
        "lambda:GetAccountSettings",
        "lambda:GetAlias",
        "lambda:GetFunction",
        "lambda:GetFunctionConcurrency",
        "lambda:GetFunctionConfiguration",
        "lambda:GetFunctionEventInvokeConfig",
        "lambda:GetLayerVersion",
        "lambda:GetLayerVersionByArn",
        "lambda:GetLayerVersionPolicy",
        "lambda:GetPolicy",
        "lambda:ListAliases",
        "lambda:ListEventSourceMappings",
        "lambda:ListFunctions",
        "lambda:ListLayerVersions",
        "lambda:ListLayers",
        "lambda:ListTags",
        "tag:GetResources",
        "s3:GetBucketAcl",
        "s3:GetBucketCORS",
        "s3:GetBucketLocation",
        "s3:GetBucketNotification",
        "s3:GetBucketObjectLockConfiguration",
        "s3:GetBucketPolicy",
        "s3:ListAllMyBuckets",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:ListDeadLetterSourceQueues",
        "sqs:ListQueues",
        "sqs:PurgeQueue",
        "support:*",
        "states:Describe*",
        "states:GetExecutionHistory",
        "states:List*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
EOT
}

resource "aws_iam_role_policy_attachment" "support" {
  role       = aws_iam_role.support.name
  policy_arn = aws_iam_policy.support.arn
}
