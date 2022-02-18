# Usage

```bash
# init
terraform init
# plan
terraform plan

# apply the change
terraform apply

# or apply the change with variables. Make sure to replace placeholder values with  actual values
terraform apply -var aws_partition=value -var aws_account_id=value -var panther_aws_account_id=value -var role_suffix=value -var s3_bucket_name=value -var managed_bucket_notifications_enabled=value
```
