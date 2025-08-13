# Preflight Tools User Guide

## Readiness Check

**Prerequisite**: A deployed "PantherDeploymentRole" in the aws account

Invoking the readiness check is simple. It does not require a payload and can either be invoked on the command line with something like this

```
aws lambda invoke --function-name "PantherReadinessCheck" --cli-binary-format raw-in-base64-out output.json
```

The result will end up in output.json in this example

```
[12:18] user@host $> aws lambda invoke --function-name "PantherReadinessCheck" --cli-binary-format raw-in-base64-out output.json
[12:18] user@host $> cat output.json
{"Message": "All evaluations were successful against the Deployment Role"}
```

Or in the console on the test page of the lambda utility:
https://console.aws.amazon.com/lambda/home#/functions/PantherReadinessCheck?tab=testing where the result will show up in the Details dropdown or in cloudwatch.

The return value of the lambda will be a json object either with a success message, or a failure message and a series of failures that were detected. Please return this result to your panther representative.
