# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.
"""
Logic for checking whether S3Select is enabled on the target account.
"""

import io
import boto3
import logging
import uuid

# 1. create a uniquely named bucket - panther-readiness-check-*
# 2. upload dummy JSON file to the bucket
# 3. S3Select content from said bucket - select statement should be valid
# 4. delete dummy JSON file
# 5. delete bucket
# 6. report readiness


class S3SelectEnabledCheck:
    def __init__(self, log: logging.Logger):
        self.log = log
        self.test_bucket_name = f'panther-readiness-check-{str(uuid.uuid4())}'
        self.test_bucket_region = boto3.session.Session().region_name
        self.test_key = 'test.json'
        self.s3 = boto3.client('s3')

    def is_enabled(self) -> bool:
        """
        check if S3Select is enabled
        """

        try:
            self._setup_bucket()
            self._create_dummy_json_file()
        except Exception as e:
            self.log.critical(
                f'failed to setup test s3 bucket ({self.test_bucket_name}) and create dummy file - exception: {e}')
            raise

        is_enabled = True

        # do the check
        try:
            key = self.test_key
            expression_type = 'SQL'
            expression = """SELECT * FROM S3Object"""
            input_serialization = {'JSON': {'Type': 'Document'}}
            output_serialization = {'JSON': {}}
            resp = self.s3.select_object_content(
                Bucket=self.test_bucket_name,
                Key=key,
                ExpressionType=expression_type,
                Expression=expression,
                InputSerialization=input_serialization,
                OutputSerialization=output_serialization
            )
            self.log.info(f'S3Select is enabled - response: {resp}')
        except Exception as e:
            self.log.error(f'failed to run S3Select on test bucket ({self.test_bucket_name}) - exception: {e}')
            self.log.error(f'S3Select does NOT appear to be enabled')
            is_enabled = False

        try:
            self._delete_dummy_json_file()
            self._cleanup_bucket()
        except Exception as e:
            self.log.critical(
                f'failed to delete dummy file and cleanup test s3 bucket ({self.test_bucket_name}) - exception: {e}')
            raise

        return is_enabled

    def _setup_bucket(self):
        self.log.info(f'setting up test s3 bucket ({self.test_bucket_name}) with LocationConstraint ({self.test_bucket_region})')
        try:
            self.s3.create_bucket(Bucket=self.test_bucket_name, CreateBucketConfiguration={
                'LocationConstraint': self.test_bucket_region})
            self.log.info(f'test s3 bucket ({self.test_bucket_name}) created')
        except Exception as e:
            self.log.info(f'failed to create test s3 bucket ({self.test_bucket_name}) with LocationConstraint ({self.test_bucket_region}) - exception: {e} - retrying without LocationConstraint, please request access to S3Select')
            self.s3.create_bucket(Bucket=self.test_bucket_name)
            self.log.info(f'test s3 bucket ({self.test_bucket_name}) created without LocationConstraint')


    def _cleanup_bucket(self):
        self.log.info(f'cleaning up test s3 bucket ({self.test_bucket_name})')
        self.s3.delete_bucket(Bucket=self.test_bucket_name)

    def _create_dummy_json_file(self):
        self.log.info('creating dummy json file')
        json = '{"hello": "world"}'
        self.s3.put_object(Bucket=self.test_bucket_name, Key=self.test_key, Body=json, ContentType='application/json')

    def _delete_dummy_json_file(self):
        self.log.info('deleting dummy json file')
        self.s3.delete_object(Bucket=self.test_bucket_name, Key=self.test_key)
