"""
Lambda function to check readiness of the current aws account to receive a Panther deployment
"""

import json
from typing import Any

from deployment_role_check import check_deployment_role_readiness
from logger import log


def lambda_handler(args: dict[str, Any], __: Any) -> dict:
    """
    Lambda entrypoint.  Accepts no input values. The "where" of it's running is
    the most important aspect.
    """

    # Lambda is insane. If you give the lambda no input when you invoke it, it
    # passes a string of '{}' to the function. If you pass it an argument, it
    # passes a dict.
    if args == "{}":
        args = json.loads(args)

    ret = {
        "deployment_role_readiness_results": check_deployment_role_readiness(),
    }

    return ret


if __name__ == "__main__":
    print(lambda_handler({}))
