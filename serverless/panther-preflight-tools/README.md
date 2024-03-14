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

## Snowflake Credential Bootstrap

After creating the PANTHERACCOUNTADMIN user and ensuring it has ACCOUNTADMIN privs, you may invoke the lambda to populate the initial credential secrets.
Authenticate to your aws environment and region where the template was stood up, then run this, filling out the host parameter with your login url

```
aws lambda invoke\
 --function-name "PantherSnowflakeCredentialBootstrap"\
 --log-type Tail\
 --payload '{"host": "https://myaccountid.snowflakecomputing.com"}'\
 --cli-binary-format raw-in-base64-out /dev/stderr > /dev/null
```

This invocation should yeild a link and instructions to update the newly minted secret directly with your credentials.
After that is done, please run the validation step below as-is and return the result to your panther representative.

```
aws lambda invoke\
 --function-name "PantherSnowflakeCredentialBootstrap"\
 --log-type Tail\
 --payload '{"validate": true}'\
 --cli-binary-format raw-in-base64-out /dev/stderr > /dev/null
```
