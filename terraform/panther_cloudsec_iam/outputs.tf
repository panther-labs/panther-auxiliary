output "panther_audit_role_arn" {
  value       = var.include_audit_role ? aws_iam_role.panther_audit[0].arn : "N/A"
  description = "The ARN of the Panther Audit IAM Role"
}

output "panther_cloud_formation_stackset_execution_role_arn" {
  value       = var.include_stack_set_execution_role ? aws_iam_role.panther_cloud_formation_stackset_execution[0].arn : "N/A"
  description = "The ARN of the CloudFormation StackSet Execution IAM Role"
}
