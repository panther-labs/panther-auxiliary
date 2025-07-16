
"""
Lambda function to check readiness of the current aws account to receive a Panther deployment
"""

from typing import Any
from s3_select_check import check_s3_select_readiness
from deployment_role_check import check_deployment_role_readiness
from logger import log

import json


def lambda_handler(args: dict[str, Any], __: Any) -> dict:
    """
    Lambda entrypoint.  Accepts no input values. The "where" of it's running is
    the most important aspect.
    """

    # Lambda is insane. If you give the lambda no input when you invoke it, it
    # passes a string of '{}' to the function. If you pass it an argument, it
    # passes a dict.
    if args == '{}':
        args = json.loads(args)

    ret = {
        'deployment_role_readiness_results': check_deployment_role_readiness(),
    }

    # S3Select is going away, but we'll keep the check just in case.
    if args.get('s3_select_check', False):
        ret['s3_select_enabled'] = check_s3_select_readiness()

    return ret


if __name__ == "__main__":
    print(lambda_handler({}))
