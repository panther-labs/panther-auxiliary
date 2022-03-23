# Usage

```bash
# init
terraform init
# plan
terraform plan

# apply the change
terraform apply

# or apply the change with variables. Make sure to replace placeholder values with  actual values
terraform apply -var aws_partition=value -var panther_aws_account_id=value -var panther_aws_account_region=value -var include_audit_role=true -var include_stack_set_execution_role=true
```
