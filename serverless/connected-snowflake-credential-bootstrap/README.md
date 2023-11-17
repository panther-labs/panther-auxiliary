**Invoking the lambda**

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
