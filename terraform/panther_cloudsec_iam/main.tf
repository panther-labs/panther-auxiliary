# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.



##### IAM roles for an account being scanned by Panther #####

###############################################################
# Policy Audit Role
###############################################################

resource "aws_iam_role" "panther_audit" {
  count       = var.include_audit_role ? 1 : 0
  name        = "PantherAuditRole-${var.panther_aws_account_region}"
  description = "The Panther account assumes this role for read-only security scanning"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          AWS : "arn:${var.aws_partition}:iam::${var.panther_aws_account_id}:root"
        },
        Action : "sts:AssumeRole",
        Condition : {
          Bool : { "aws:SecureTransport" : true }
        }
      }
    ]
  })

  tags = {
    Application = "Panther"
  }
}

resource "aws_iam_role_policy_attachment" "security_audit" {
  count      = var.include_audit_role ? 1 : 0
  role       = aws_iam_role.panther_audit[0].id
  policy_arn = "arn:${var.aws_partition}:iam::aws:policy/SecurityAudit"
}

# CloudFormationStackDriftDetection and CloudFormationStackDriftDetectionSupplements Policies
# are not directly required for scanning, but are required by AWS in
# order to perform CloudFormation Stack drift detection on the corresponding resource types
# If you delete those policies,
# make sure to exclude CloudFormation stacks from your cloud security source setup,
# otherwise you will be notified every 24 hours that those scans are failing.
resource "aws_iam_role_policy" "panther_cloud_formation_stack_drift_detection" {
  count = var.include_audit_role ? 1 : 0
  name  = "CloudFormationStackDriftDetection"
  role  = aws_iam_role.panther_audit[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "cloudformation:DetectStackDrift",
          "cloudformation:DetectStackResourceDrift"
        ],
        Resource : "*"
      }
    ]
  })
}


resource "aws_iam_role_policy" "panther_cloud_formation_stack_drift_detection_supplements" {
  count = var.include_audit_role ? 1 : 0
  name  = "CloudFormationStackDriftDetectionSupplements"
  role  = aws_iam_role.panther_audit[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "apigateway:GET",
          "lambda:GetFunction",
          "sns:ListTagsForResource"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "panther_get_waf_acls" {
  count = var.include_audit_role ? 1 : 0
  name  = "GetWAFACLs"
  role  = aws_iam_role.panther_audit[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "waf:GetRateBasedRule",
          "waf:GetRule",
          "waf:GetRuleGroup",
          "waf:GetWebACL",
          "waf-regional:GetRateBasedRule",
          "waf-regional:GetRule",
          "waf-regional:GetRuleGroup",
          "waf-regional:GetWebACL",
          "waf-regional:GetWebACLForResource"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "panther_get_tags" {
  count = var.include_audit_role ? 1 : 0
  name  = "GetTags"
  role  = aws_iam_role.panther_audit[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "dynamodb:ListTagsOfResource",
          "kms:ListResourceTags",
          "waf:ListTagsForResource",
          "waf-regional:ListTagsForResource"
        ],
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "panther_list_describe_eks" {
  count = var.include_audit_role ? 1 : 0
  name  = "ListDescribeEKS"
  role  = aws_iam_role.panther_audit[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "eks:ListClusters",
          "eks:ListFargateProfiles",
          "eks:ListNodegroups",
          "eks:DescribeCluster",
          "eks:DescribeFargateProfile",
          "eks:DescribeNodegroup",
        ],
        Resource : "*"
      }
    ]
  })
}


###############################################################
# CloudFormation StackSet Execution Role
###############################################################

resource "aws_iam_role" "panther_cloud_formation_stackset_execution" {
  count       = var.include_stack_set_execution_role ? 1 : 0
  name        = "PantherCloudFormationStackSetExecutionRole-${var.panther_aws_account_region}"
  description = "CloudFormation assumes this role to execute a stack set"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Principal : {
          "AWS" : "arn:${var.aws_partition}:iam::${var.panther_aws_account_id}:root"
        },
        Action : "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Application = "Panther"
  }
}

resource "aws_iam_role_policy" "panther_manage_cloud_formation_stack" {
  count = var.include_stack_set_execution_role ? 1 : 0
  name  = "ManageCloudFormationStack"
  role  = aws_iam_role.panther_cloud_formation_stackset_execution[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : "cloudformation:*",
        Resource : "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "panther_setup_realtime_events" {
  count = var.include_stack_set_execution_role ? 1 : 0
  name  = "PantherSetupRealTimeEvents"
  role  = aws_iam_role.panther_cloud_formation_stackset_execution[0].id

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "events:*",
          "sns:*"
        ],
        Resource : "*"
      }
    ]
  })
}
