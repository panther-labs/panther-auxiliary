# Copyright (C) 2020 Panther Labs Inc
#
# Panther Enterprise is licensed under the terms of a commercial license available from
# Panther Labs Inc ("Panther Commercial License") by contacting contact@runpanther.com.
# All use, distribution, and/or modification of this software, whether commercial or non-commercial,
# falls under the Panther Commercial License to the extent it is permitted.




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