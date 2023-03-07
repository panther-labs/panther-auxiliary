# Usage

```bash
# make sure you are on the right directory and logged in with the `gcloud` tool

# Dry-run
terraform init
terraform plan

# apply the change
terraform apply

# or apply the change with a variables file.
terraform apply -var-file="production.tfvars"
```
