# Usage

```bash
# make sure you are on the right aws account

# Dry-run
terraform init
terraform plan

# apply the change
terraform apply

# or apply the change with variables. Make sure to replace placeholder values with  actual values
terraform apply -var panther_aws_account_id=value -var stack_name=value -var cloudwatch_log_group_name=value
```
