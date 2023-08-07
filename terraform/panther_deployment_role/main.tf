# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.



resource "aws_iam_role" "deployment" {
  name        = var.deployment_role_name
  description = "IAM role for deploying Panther"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : var.assume_role_principal == "" ? "arn:${var.aws_partition}:iam::${var.aws_account_id}:root" : var.assume_role_principal
        }
        Action : "sts:AssumeRole",
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      },
      {
        Effect : "Allow",
        Principal : {
          Service : "cloudformation.amazonaws.com"
        }
        Action : "sts:AssumeRole",
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      },
    ]
  })

  tags = {
    Application = "Panther"
  }
}

resource "aws_iam_policy" "deployment" {
  name = "PantherDeployment"

  # DO NOT EDIT - policy is automatically copied from CloudFormation by 'mage fmt'
  policy = <<EOT
{
  "Statement": [
    {
      "Action": [
        "acm:*",
        "apigateway:*",
        "application-autoscaling:*ScalableTarget*",
        "application-autoscaling:*ScalingPolicies",
        "application-autoscaling:*ScalingPolicy",
        "athena:*",
        "backup-storage:*",
        "backup:*",
        "batch:*",
        "cloudformation:*",
        "cloudfront:UpdateDistribution",
        "cloudtrail:*",
        "cloudwatch:*Alarm*",
        "cloudwatch:*Dashboard*",
        "cloudwatch:*Metric*",
        "cloudwatch:*Tag*",
        "cloudwatch:List*",
        "codebuild:*",
        "cognito-idp:*",
        "dynamodb:*Backup*",
        "dynamodb:*Stream*",
        "dynamodb:*Table*",
        "dynamodb:*Tag*",
        "dynamodb:*TimeToLive*",
        "ec2:*",
        "ecr:GetAuthorizationToken",
        "ecs:*Cluster*",
        "ecs:*Service*",
        "ecs:*Tag*",
        "ecs:*Task*",
        "elasticfilesystem:*",
        "elasticloadbalancing:*",
        "es:*",
        "events:*",
        "glue:*",
        "iam:*Policy*",
        "iam:*ServerCertificate",
        "iam:CreateRole",
        "iam:Get*",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:ListAccountAliases",
        "iam:ListAttachedRolePolicies",
        "iam:ListRolePolicies",
        "iam:PutRolePolicy",
        "iam:TagRole",
        "kinesis:AddTagsToStream",
        "kinesis:CreateStream",
        "kinesis:DescribeStreamSummary",
        "kinesis:EnableEnhancedMonitoring",
        "kinesis:IncreaseStreamRetentionPeriod",
        "kinesis:ListTagsForStream",
        "kms:*",
        "lambda:*EventSourceMapping",
        "lambda:*LayerVersion*",
        "lambda:List*",
        "logs:*",
        "organizations:DescribeOrganization",
        "s3:*AccelerateConfiguration",
        "s3:*AccountPublicAccessBlock",
        "s3:*Bucket*",
        "s3:*EncryptionConfiguration",
        "s3:*InventoryConfiguration",
        "s3:*LifecycleConfiguration",
        "s3:*MetricsConfiguration",
        "s3:*ReplicationConfiguration",
        "s3:CreateAccessPoint",
        "s3:PutObject*",
        "secretsmanager:Describe*",
        "secretsmanager:List*",
        "servicequotas:*",
        "sns:*",
        "sqs:*Permission*",
        "sqs:*Queue*",
        "sqs:SendMessage",
        "states:*",
        "vpc:*",
        "wafv2:*",
        "wafv2:CreateRuleGroup",
        "wafv2:CreateWebACL",
        "wafv2:GetRuleGroup",
        "wafv2:ListTagsForResource",
        "wafv2:TagResource",
        "wafv2:UpdateRuleGroup"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": "secretsmanager:*",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:secretsmanager:*:${var.aws_account_id}:secret:panther*"
    },
    {
      "Action": "firehose:*",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:firehose:*:${var.aws_account_id}:deliverystream/*"
    },
    {
      "Action": [
        "dynamodb:Scan",
        "dynamodb:Get*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/panther-analysis",
        "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/panther-organization"
      ]
    },
    {
      "Action": [
        "iam:*InstanceProfile*",
        "iam:AttachRolePolicy",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:Get*",
        "iam:List*",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:TagRole",
        "iam:UpdateAssumeRolePolicy",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription",
        "iam:UntagRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/dynamo-scaling-*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/firehose-http-input-data-bucket-*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/panther-*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/Panther*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/pip-layer-builder-codebuild-*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:instance-profile/Panther*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/datadog*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/Datadog*"
      ]
    },
    {
      "Action": [
        "iam:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/batch.amazonaws.com/AWSServiceRoleForBatch",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/cloudtrail.amazonaws.com/AWSServiceRoleForCloudTrail",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/dynamodb.application-autoscaling.amazonaws.com/AWSServiceRoleForApplicationAutoScaling_DynamoDBTable",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/elasticfilesystem.amazonaws.com/AWSServiceRoleForAmazonElasticFileSystem",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/guardduty.amazonaws.com/AWSServiceRoleForAmazonGuardDuty",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/opensearchservice.amazonaws.com/AWSServiceRoleForAmazonOpenSearchService",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/ops.apigateway.amazonaws.com/AWSServiceRoleForAPIGateway",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/servicequotas.amazonaws.com/AWSServiceRoleForServiceQuotas"
      ]
    },
    {
      "Action": [
        "sts:AssumeRole"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:iam::*:role/PulumiRoute53"
    },
    {
      "Action": "lambda:*",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:lambda:${var.aws_region}:${var.aws_account_id}:event-source-mapping:*",
        "arn:${var.aws_partition}:lambda:${var.aws_region}:${var.aws_account_id}:function:panther-*",
        "arn:${var.aws_partition}:lambda:${var.aws_region}:${var.aws_account_id}:layer:panther-*",
        "arn:${var.aws_partition}:lambda:${var.aws_region}:${var.aws_account_id}:function:datadog-*"
      ]
    },
    {
      "Action": "lambda:invokeFunction",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:lambda:${var.aws_region}:${var.aws_account_id}:function:panther-source-api"
    },
    {
      "Action": "lambda:GetLayerVersion",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:lambda:${var.aws_region}:464622532012:layer:Datadog-Extension*",
        "arn:${var.aws_partition}:lambda:${var.aws_region}:464622532012:layer:Datadog-Python*",
        "arn:${var.aws_partition}:lambda:${var.aws_region}:580247275435:layer:LambdaInsightsExtension*"
      ]
    },
    {
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:ecr:${var.aws_region}:*:repository/panther-enterprise",
        "arn:${var.aws_partition}:ecr:${var.aws_region}:*:repository/panther-internal-rc"
      ]
    },
    {
      "Action": [
        "s3:Get*",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:s3:::panther-enterprise-${var.aws_region}*",
        "arn:${var.aws_partition}:s3:::panther-internal-rc-${var.aws_region}*"
      ]
    },
    {
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:s3:::panther*-analysisversions-*",
        "arn:${var.aws_partition}:s3:::analysis-versions-*"
      ]
    },
    {
      "Action": "elasticloadbalancing:DeleteLoadBalancer",
      "Effect": "Deny",
      "NotResource": [
        "arn:${var.aws_partition}:elasticloadbalancing:${var.aws_region}:${var.aws_account_id}:loadbalancer/app/http-ingest-alb*"
      ]
    },
    {
      "Action": "dynamodb:DeleteTable",
      "Effect": "Deny",
      "NotResource": [
        "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/*alerts-risk-factors",
        "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/*alerts-indicators",
        "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/*alert-search-rehydrate-jobs"
      ]
    },
    {
      "Action": [
        "cognito-idp:DeleteUserPool*",
        "dynamodb:DeleteBackup",
        "dynamodb:DeleteItem",
        "dynamodb:DeleteTableReplica",
        "kms:DeleteAlias",
        "kms:DeleteCustomKeyStore",
        "kms:DeleteImportedKeyMaterial",
        "kms:ScheduleKeyDeletion",
        "s3:DeleteBucket",
        "sns:DeleteTopic"
      ],
      "Effect": "Deny",
      "Resource": "*"
    }
  ],
  "Version": "2012-10-17"
}
EOT
}

resource "aws_iam_role_policy_attachment" "deployment" {
  role       = aws_iam_role.deployment.name
  policy_arn = aws_iam_policy.deployment.arn
}
