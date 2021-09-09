# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.



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
        "application-autoscaling:DeleteScalingPolicy",
        "application-autoscaling:DeregisterScalableTarget",
        "application-autoscaling:DescribeScalingPolicies",
        "application-autoscaling:DescribeScalableTargets",
        "application-autoscaling:PutScalingPolicy",
        "application-autoscaling:RegisterScalableTarget",
        "appsync:*",
        "athena:*",
        "cloudformation:Describe*",
        "cloudformation:List*",
        "cloudfront:UpdateDistribution",
        "cloudtrail:DescribeTrails",
        "cloudtrail:CreateTrail",
        "cloudwatch:*",
        "cognito-idp:*",
        "dynamodb:List*",
        "ec2:AllocateAddress",
        "ec2:AssociateRouteTable",
        "ec2:AssociateSubnetCidrBlock",
        "ec2:AssociateVpcCidrBlock",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AttachInternetGateway",
        "ec2:CreateVpcEndpoint",
        "ec2:CreateFlowLogs",
        "ec2:CreateInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:CreateNetworkInterface",
        "ec2:CreateRoute",
        "ec2:CreateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:CreateSubnet",
        "ec2:CreateTags",
        "ec2:CreateVpc",
        "ec2:DeleteVpcEndpoints",
        "ec2:DeleteVpcEndpoint",
        "ec2:DeleteFlowLogs",
        "ec2:DeleteInternetGateway",
        "ec2:DeleteNatGateway",
        "ec2:DeleteRoute",
        "ec2:DeleteRouteTable",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteSubnet",
        "ec2:DeleteTags",
        "ec2:DeleteVpc",
        "ec2:Describe*",
        "ec2:DetachInternetGateway",
        "ec2:DisassociateAddress",
        "ec2:DisassociateRouteTable",
        "ec2:DisassociateSubnetCidrBlock",
        "ec2:ModifySubnetAttribute",
        "ec2:ModifyVpcAttribute",
        "ec2:ModifyVpcEndpoint",
        "ec2:ReleaseAddress",
        "ec2:ReplaceRoute",
        "ec2:ReplaceRouteTableAssociation",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:UpdateSecurityGroupRuleDescriptionsEgress",
        "ec2:UpdateSecurityGroupRuleDescriptionsIngress",
        "elasticfilesystem:ClientMount",
        "elasticfilesystem:ClientRootAccess",
        "elasticfilesystem:ClientWrite",
        "elasticfilesystem:CreateAccessPoint",
        "elasticfilesystem:CreateFileSystem",
        "elasticfilesystem:CreateMountTarget",
        "elasticfilesystem:DeleteAccessPoint",
        "elasticfilesystem:DeleteFileSystem",
        "elasticfilesystem:DeleteMountTarget",
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeFileSystemPolicy",
        "elasticfilesystem:DescribeLifecycleConfiguration",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeMountTargetSecurityGroups",
        "elasticfilesystem:ModifyMountTargetSecurityGroups",
        "elasticfilesystem:PutLifecycleConfiguration",
        "elasticfilesystem:PutFileSystemPolicy",
        "elasticfilesystem:ListTagsForResource",
        "elasticfilesystem:TagResource",
        "elasticfilesystem:UntagResource",
        "elasticfilesystem:UpdateFileSystem",
        "elasticloadbalancing:*",
        "ecr:GetAuthorizationToken",
        "ecs:*",
        "events:*",
        "firehose:ListDeliveryStreams",
        "glue:*",
        "guardduty:CreatePublishingDestination",
        "guardduty:ListDetectors",
        "kms:CreateKey",
        "kms:List*",
        "lambda:*EventSourceMapping",
        "lambda:List*",
        "logs:*",
        "s3:ListAllMyBuckets",
        "sns:List*",
        "sqs:List*",
        "states:CreateStateMachine",
        "states:TagResource",
        "states:UntagResource"
      ],
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "cloudtrail:AddTags",
        "cloudtrail:DeleteTrail",
        "cloudtrail:PutEventSelectors",
        "cloudtrail:StartLogging",
        "cloudtrail:StopLogging",
        "cloudtrail:UpdateTrail"
      ],
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:cloudtrail:*:${var.aws_account_id}:trail/panther-cloudtrail-*"
    },
    {
      "Action": "cloudformation:*",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:cloudformation:*:${var.aws_account_id}:stack/panther*",
        "arn:${var.aws_partition}:cloudformation:*:${var.aws_account_id}:stackset/panther*",
        "arn:${var.aws_partition}:cloudformation:*:aws:transform/Serverless-2016-10-31"
      ]
    },
    {
      "Action": "codebuild:*",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:codebuild:*:${var.aws_account_id}:project/panther-pulumi"
    },
    {
      "Action": "serverlessrepo:*",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:serverlessrepo:*:*:applications/*"
    },
    {
      "Action": "s3:GetObject",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:s3:::awsserverlessrepo-changesets-*"
    },
    {
      "Action": [
        "dynamodb:CreateTable",
        "dynamodb:DeleteTable",
        "dynamodb:Describe*",
        "dynamodb:TagResource",
        "dynamodb:UntagResource",
        "dynamodb:UpdateContinuousBackups",
        "dynamodb:UpdateTable",
        "dynamodb:UpdateTimeToLive"
      ],
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:dynamodb:*:${var.aws_account_id}:table/panther-*"
    },
    {
      "Action": "firehose:*",
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:firehose:*:${var.aws_account_id}:deliverystream/panther-*"
    },
    {
      "Action": [
        "iam:AttachRolePolicy",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:DeleteRolePolicy",
        "iam:DetachRolePolicy",
        "iam:GetRole",
        "iam:GetRolePolicy",
        "iam:PassRole",
        "iam:PutRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:UpdateRole",
        "iam:UpdateRoleDescription",
        "iam:*ServerCertificate",
        "iam:CreateServiceLinkedRole"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/AWSServiceRole*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/aws-service-role/*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/panther-*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/Panther*",
        "arn:${var.aws_partition}:iam::${var.aws_account_id}:server-certificate/panther/*"
      ]
    },
    {
      "Action": [
        "kms:CreateAlias",
        "kms:Decrypt",
        "kms:DeleteAlias",
        "kms:DescribeKey",
        "kms:DisableKeyRotation",
        "kms:EnableKeyRotation",
        "kms:GetKeyPolicy",
        "kms:GetKeyRotationStatus",
        "kms:ListResourceTags",
        "kms:PutKeyPolicy",
        "kms:ScheduleKeyDeletion",
        "kms:TagResource",
        "kms:UntagResource",
        "kms:UpdateAlias",
        "kms:UpdateKeyDescription"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:kms:*:${var.aws_account_id}:alias/panther-*",
        "arn:${var.aws_partition}:kms:*:${var.aws_account_id}:key/*"
      ]
    },
    {
      "Action": [
        "lambda:AddLayerVersionPermission",
        "lambda:AddPermission",
        "lambda:CreateFunction",
        "lambda:Delete*",
        "lambda:Get*",
        "lambda:PublishLayerVersion",
        "lambda:Put*",
        "lambda:RemoveLayerVersionPermission",
        "lambda:RemovePermission",
        "lambda:TagResource",
        "lambda:UntagResource",
        "lambda:Update*"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:event-source-mapping:*",
        "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:function:panther-*",
        "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:layer:panther-*"
      ]
    },
    {
      "Action": "lambda:InvokeFunction",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:function:panther-cfn-custom-resources",
        "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:function:panther-pip-layer-builder"
      ]
    },
    {
      "Action": [
        "s3:CreateBucket",
        "s3:DeleteBucket*",
        "s3:GetBucket*",
        "s3:Get*Configuration",
        "s3:PutBucket*",
        "s3:Put*Configuration"
      ],
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:s3:::panther-*"
    },
    {
      "Action": "s3:GetObject",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:s3:::panther*-analysisversions-*/layers/*",
        "arn:${var.aws_partition}:s3:::panther-dev-sourcebucket-*",
        "arn:${var.aws_partition}:s3:::panther-enterprise-*"
      ]
    },
    {
      "Action": [
        "sns:AddPermission",
        "sns:CreateTopic",
        "sns:DeleteTopic",
        "sns:GetTopicAttributes",
        "sns:RemovePermission",
        "sns:SetTopicAttributes",
        "sns:Subscribe",
        "sns:TagResource",
        "sns:Unsubscribe",
        "sns:UntagResource"
      ],
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:sns:*:${var.aws_account_id}:panther-*"
    },
    {
      "Action": [
        "sqs:AddPermission",
        "sqs:CreateQueue",
        "sqs:DeleteQueue",
        "sqs:GetQueueAttributes",
        "sqs:GetQueueUrl",
        "sqs:SetQueueAttributes",
        "sqs:TagQueue",
        "sqs:UntagQueue"
      ],
      "Effect": "Allow",
      "Resource": "arn:${var.aws_partition}:sqs:*:${var.aws_account_id}:panther-*"
    },
    {
      "Action": "states:*",
      "Effect": "Allow",
      "Resource": [
        "arn:${var.aws_partition}:states:*:${var.aws_account_id}:activity:panther-*",
        "arn:${var.aws_partition}:states:*:${var.aws_account_id}:execution:panther-*:*",
        "arn:${var.aws_partition}:states:*:${var.aws_account_id}:stateMachine:panther-*"
      ]
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
