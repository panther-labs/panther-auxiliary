# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.




#####
# Panther IAM Role for creating and managing StackSets. The purpose of this role is to assume
# the execution IAM roles in each target account for configuring various Panther infrastructure.

resource "aws_iam_role" "stack_set_admin" {
  name = "PantherCloudFormationStackSetAdminRole-${var.aws_region}"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          Service : "cloudformation.amazonaws.com"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "stack_set_admin" {
  name = "AssumeRolesInTargetAccounts"
  role = aws_iam_role.stack_set_admin.id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "sts:AssumeRole",
        Resource : "arn:${var.aws_partition}:iam::*:role/PantherCloudFormationStackSetExecutionRole-${var.aws_region}"
      }
    ]
  })
}
