# Usage

```bash
# make sure you are on the right directory and logged into azure` with the `az` tool

# Dry-run
terraform init
terraform plan

# apply the change
terraform apply

# or apply the change with a variables file.
terraform apply -var-file="panther.tfvars"
```
