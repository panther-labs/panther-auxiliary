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

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AWSCloudFormationReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSLambda_ReadOnlyAccess",
  ]

  inline_policy {
    name = "PantherSourceDeploy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "cloudwatch:*",
            "codebuild:List*",
            "ecr:GetAuthorizationToken",
            "kms:Describe*",
            "kms:List*",
            "logs:*",
            "secretsmanager:List*"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = "cloudformation:*"
          Resource = [
            "arn:${var.aws_partition}:cloudformation:*:${var.aws_account_id}:stack/panther*",
            "arn:${var.aws_partition}:cloudformation:*:${var.aws_account_id}:stackset/panther*",
            "arn:${var.aws_partition}:cloudformation:*:aws:transform/Serverless-2016-10-31"
          ]
        },
        {
          Effect   = "Allow"
          Action   = "codebuild:*"
          Resource = "arn:${var.aws_partition}:codebuild:*:${var.aws_account_id}:project/panther-pulumi"
        },
        {
          Effect   = "Allow"
          Action   = "ecr:*"
          Resource = "arn:${var.aws_partition}:ecr:*:${var.aws_account_id}:repository/panther-web-dev"
        },
        {
          Effect   = "Allow"
          Action   = "iam:*"
          Resource = "arn:${var.aws_partition}:iam::${var.aws_account_id}:role/PantherDevDeploymentRole-*"
        },
        {
          Effect   = "Allow"
          Action   = "lambda:InvokeFunction"
          Resource = "arn:${var.aws_partition}:lambda:*:${var.aws_account_id}:function:panther-users-api"
        },
        {
          Effect   = "Allow"
          Action   = "s3:*"
          Resource = "arn:${var.aws_partition}:s3:::panther-dev-sourcebucket-*"
        },
        {
          Effect   = "Allow"
          Action   = "secretsmanager:*"
          Resource = "arn:${var.aws_partition}:secretsmanager:*:${var.aws_account_id}:secret:panther*"
        },
      ]
    })
  }

  tags = {
    "panther:app" = "panther"
  }
}
