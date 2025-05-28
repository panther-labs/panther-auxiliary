# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.
"""
Lambda function to assist the user in setting up their AWS account
to accept a Panther deployment configured to use a connected, pre-existing
snowflake account
"""

from typing import Any
from dataclasses import dataclass
import json
import os
from typing import Mapping
from urllib.parse import urlparse, ParseResult

import boto3
from botocore.exceptions import ClientError
import snowflake.connector
from cryptography.hazmat.backends import default_backend
from cryptography.hazmat.primitives.serialization import load_pem_private_key

SECRETNAME = "panther-managed-accountadmin-secret"
SF_DOMAIN = ".snowflakecomputing.com"
USERNAME = "PANTHERACCOUNTADMIN"
PASSWORD_PLACEHOLDER = "PleaseReplaceMe"
PRIVATE_KEY_PLACEHOLDER = "PleaseReplaceMeWithPrivateKey"

# What region are we in
AWS_REGION = os.environ.get("AWS_REGION", "")
AWS_DEFAULT_REGION = os.environ.get("AWS_DEFAULT_REGION", "")
if not AWS_REGION and not AWS_DEFAULT_REGION:
    raise EnvironmentError("Could not detect region")
REGION = AWS_REGION if AWS_REGION else AWS_DEFAULT_REGION

SECRET_URL = f"https://{REGION}.console.aws.amazon.com/secretsmanager/secret?name={SECRETNAME}&region={REGION}"

EDIT_SECRET_PROMPT = f"""Please navigate to {SECRET_URL} in your authenticated browser and click \
"Retrieve secret value" then "Edit".  Add your RSA private key in place of the placeholder and save \
the secret.  Then return to your terminal and execute the lambda again with "validate":true"""


@dataclass
class PantherSnowflakeCredential:
    """
    Represent the credentials used by panther to authenticate to snowflake
    """

    arn: str = ""
    host: str = ""
    account: str = ""
    user: str = ""
    password: str = PASSWORD_PLACEHOLDER
    privateKey1: str = PRIVATE_KEY_PLACEHOLDER
    port: str = "443"

    @staticmethod
    def secret_exists(client: boto3.Session) -> bool:
        """
        Checks for the existence of the managed accountadmin secret
        return: true if exists, false if not
        """
        try:
            client.describe_secret(SecretId=SECRETNAME)
            return True
        except ClientError as error:
            if error.response["Error"]["Code"] == "ResourceNotFoundException":
                return False
            raise

    def create_secret(self, client: boto3.Session) -> None:
        """
        Json-ifies the class and writes to the secret
        return: ARN of newly created secret
        """
        secret_string = json.dumps(
            {
                "account": self.account,
                "host": self.host,
                "port": self.port,
                "user": self.user,
                "privateKey1": self.privateKey1,
                "password": self.password,
            }
        )
        resp = client.create_secret(
            Name=SECRETNAME,
            Description="Panther Labs, accountadmin snowflake credentials",
            SecretString=secret_string,
        )
        self.arn = resp["ARN"]

    def test(self) -> None:
        if self.password == PASSWORD_PLACEHOLDER and self.privateKey1 == PRIVATE_KEY_PLACEHOLDER:
            raise ValueError("The secret must contain either a password or a private key, but not both.")

        if self.privateKey1 != PRIVATE_KEY_PLACEHOLDER:
            self._test_keypair()
        else:
            self._test_password()

    def _test_password(self) -> None:
        snowflake.connector.connect(user=self.user, password=self.password, account=self.account)

    def _test_keypair(self) -> None:
        """
        Connects to snowflake to validate credentials
        """
        try:
            # Convert the PEM string to an RSAPrivateKey object
            private_key_obj = load_pem_private_key(
                self.privateKey1.encode('utf-8'),
                password=None,
                backend=default_backend()
            )

            # Connect to Snowflake using the RSA private key object
            snowflake.connector.connect(
                user=self.user,
                private_key=private_key_obj,
                account=self.account
            )
        except ValueError as e:
            if "Expected bytes or RSAPrivateKey" in str(e):
                print("Error: The private key is not in the correct format. It should be a PEM-formatted RSA private key.")
                print("Example format: '-----BEGIN PRIVATE KEY-----\\nMIIEvAIBADANBgkqhkiG9w0BAQEF...\\n-----END PRIVATE KEY-----'")
            raise


def credentials_from_secret(client: boto3.Session) -> PantherSnowflakeCredential:
    """
    Populates a credential object from a known-existing secret
    """
    if not PantherSnowflakeCredential.secret_exists(client):
        raise ValueError("The snowflake credential secret was expected to exist, but does not.")

    resp = client.get_secret_value(SecretId=SECRETNAME)
    secret = json.loads(resp["SecretString"])
    return PantherSnowflakeCredential(
        arn=resp["ARN"],
        account=secret["account"],
        host=secret["host"],
        port=secret["port"],
        user=secret["user"],
        privateKey1=secret["privateKey1"],
        password=secret["password"],
    )


def parse_event_into_creds(event: Mapping[str, str]) -> PantherSnowflakeCredential:
    """
    Validate, massage the input event and store it as a credential object
    return: Instance of PantherSnowflakeCredentials representing the given input, save password
    """
    for field in ["host"]:
        if field not in event.keys():
            raise ValueError(f"Failed validating input, missing field '{field}' in payload")

    user = event.get("user", USERNAME)
    host = event["host"]

    if user != USERNAME:
        raise ValueError(f"User did not match required string {USERNAME}")

    parsed: ParseResult = urlparse(host)
    host = parsed.netloc
    if not host:
        host = parsed.path
    if not host:
        raise ValueError("Failed validating input for 'host' field: should be a hostname or uri with protocol")
    if not host.endswith(SF_DOMAIN):
        raise ValueError(f"Failed validating input for 'host' field: host must end with {SF_DOMAIN}")

    return PantherSnowflakeCredential(
        host=host,
        account=host.split(SF_DOMAIN)[0],
        user=user,
        # privateKey1 is populated later by automation
        # Port always defaults to 443
    )


def lambda_handler(event: Mapping[str, str], _: Any) -> dict:
    """
    Lambda entrypoint
    """
    client = boto3.client("secretsmanager", region_name=REGION)
    # Two execution modes for the lambda.  Seed and validate the secret
    if event.get("validate", False):
        print("======VALIDATION MODE======")
        # Check creds are changed
        creds = credentials_from_secret(client)

        # Run cred test
        try:
            creds.test()
        except Exception as e:
            print(
                "Failed testing the snowflake credentials! Please check for correctness of host, user, and private key in the secret"
            )
            print(f"Error details: {str(e)}")
            raise

        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": {
                "message": f"Validation succeeded for the secret.  Please report back to your panther rep with this value: '{creds.arn}'",
                "credsArn": creds.arn,
            }
        }

    print("======SEED CREDS======")
    # Check that secret doesn't already exist
    if PantherSnowflakeCredential.secret_exists(client):
        raise FileExistsError(
            f"The proposed secret '{SECRETNAME}' already exists in this account/region! Refusing to overwrite it."
        )
    # Parse the event input
    creds = parse_event_into_creds(event)
    # Create secret
    creds.create_secret(client)
    return f"Creating the initial secret was successful.  {EDIT_SECRET_PROMPT}"
