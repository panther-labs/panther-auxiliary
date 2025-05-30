# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.
"""
Helper module for checking deployment role readiness in AWS accounts
"""

from collections import defaultdict
from itertools import product
from functools import reduce
from math import ceil
import uuid
import re
from typing import Dict, List, Any

import boto3

from cfn_expander import get_deployment_role_policies_with_expanded_actions
from logger import log


def get_aws_account() -> str:
    """
    Discover the aws account ID based on sts.get_caller_identity
    """
    sts_client = boto3.client("sts")
    return sts_client.get_caller_identity().get("Account")


def get_cloudformation_conditions() -> List[Dict[str, Any]]:
    """
    Extract condition statements from the CloudFormation template and transform
    them into context entries suitable for policy simulation.

    Returns:
        List of context entries dictionaries for the policy simulator
    """
    aws_account = get_aws_account()
    aws_region = boto3.session.Session().region_name
    # Default to 'aws' if can't determine partition
    aws_partition = 'aws'

    # Collect all conditions from the CloudFormation template
    context_entries = [
        # Bool conditions
        {
            "ContextKeyName": "aws:SecureTransport",
            "ContextKeyValues": ["true"],
            "ContextKeyType": "boolean"
        },
        # String equals conditions
        {
            "ContextKeyName": "aws:ResourceTag/panther:app",
            "ContextKeyValues": ["panther"],
            "ContextKeyType": "string"
        },
        # String like conditions with substitutions
        {
            "ContextKeyName": "apigateway:Request/apiName",
            "ContextKeyValues": [f"panther-{str(uuid.uuid4())[:8]}"],
            "ContextKeyType": "string"
        },
        {
            "ContextKeyName": "lambda:FunctionArn",
            "ContextKeyValues": [f"arn:{aws_partition}:lambda:{aws_region}:{aws_account}:function:panther-{str(uuid.uuid4())[:8]}"],
            "ContextKeyType": "string"
        }
    ]

    return context_entries


def simulate(client: boto3.client, policy_source_arn: str, actions: List[str], resources: List[str]) -> dict[str, Any]:
    """
    Simulate a set of actions against a set of resources given a policy using policysim
    """
    # Get context entries from CloudFormation conditions
    context_entries = get_cloudformation_conditions()

    log.debug("Simulating with context entries: %s", context_entries)

    return client.simulate_principal_policy(
        PolicySourceArn=policy_source_arn,
        ActionNames=actions,
        ResourceArns=resources,
        ContextEntries=context_entries
    )


def check_deployment_role_readiness() -> dict[str, Any]:
    """
    Check whether our deployment role is up to date and configured correctly.

    AWS Account ID is detected via an sts reflection call
    AWS Region is detected via AWS_* environment variables

    Uses the deployed copy of the DeploymentRole
    """

    # What account are we in
    aws_account = get_aws_account()

    # Pull down the template-filled deployment role policy, and get an action-expanded and template-filled version of the policy
    deployment_role_expanded_policies = get_deployment_role_policies_with_expanded_actions(
        role_name="PantherDeploymentRole"
    )
    # Set up a few views on the expanded policy statements
    expanded_denies = filter(
        lambda p: p.get("Effect", "") == "Deny",
        reduce(list.__add__, map(lambda p: p.get("Statement"), deployment_role_expanded_policies)),
    )
    expanded_allows = filter(
        lambda p: p.get("Effect", "") == "Allow",
        reduce(list.__add__, map(lambda p: p.get("Statement"), deployment_role_expanded_policies)),
    )

    # Denial management. Actively exclude simulations we detect will rightfully end in denial
    denies_by_resource = defaultdict(set)  # map of denies with "resource" inclusive items <resource> -> set<actions>
    deny_not_resources_by_action = defaultdict(
        set
    )  # map of denies with "notResource" exclusive items <action> -> set<resources>
    for d in expanded_denies:
        if "Resource" in d.keys():
            for p in product(d.get("Resource"), d.get("Action")):
                denies_by_resource[p[0]].add(p[1])
        if "NotResource" in d.keys():
            for p in product(d.get("NotResource"), d.get("Action")):
                deny_not_resources_by_action[p[1]].add(p[0])

    global_denies = denies_by_resource.get("*", set())

    def _get_denies(resource: str) -> set:
        """
        Returns denies that were specified by the policy for a specific resource
        Union of:
        - Denies that match the resource into an inclusive resource set
        - Global "*" denials
        - Denies defined in NotResource lists that don't include the resource
        """
        return (
            denies_by_resource.get(resource, set())
            | global_denies
            | set(map(lambda u: u[0], filter(lambda t: resource not in t[1], deny_not_resources_by_action.items())))
        )

    def _denied_evaluation(evaluation: Dict) -> bool:
        # Helper to determine if an evaluation was a success
        return evaluation.get("EvalDecision", "not_found") != "allowed" or not evaluation.get(
            "OrganizationsDecisionDetail", {}
        ).get("AllowedByOrganizations", True)

    # Evaluate all the allows, diffing out the matched denies
    iam_client = boto3.client("iam")
    failed_evaluations = []
    for expanded_policy in expanded_allows:
        p_actions = expanded_policy.get("Action", [])
        # Product of resources and actions in a request can't exceed 1000
        # Break down actions into chunks of 1k or less
        # Break multiple resources out individually
        # Run all those combos of resources and associated action blocks
        for i in range(ceil(len(p_actions) / 1000)):
            p_resources = expanded_policy.get("Resource", [])
            for resource in p_resources:
                actions = set(p_actions[i * 1000: (i + 1) * 1000])
                denials = _get_denies(resource)
                log.debug("Denies in place for <%s>: %s", resource, ", ".join(denials))
                # Doing this if any expanded actions match an explicit deny.  No sense in simulating an expected denial.
                denyless_actions = list(actions - denials)
                if denyless_actions:
                    log.debug("simulating actions %s against %s", ", ".join(denyless_actions), resource)
                    result = simulate(
                        iam_client,
                        f"arn:aws:iam::{aws_account}:role/PantherDeploymentRole",
                        denyless_actions,
                        [resource],
                    )
                    log.debug(result.get("EvaluationResults", []))
                    failed_evaluations.extend(list(filter(_denied_evaluation, result.get("EvaluationResults", []))))

    # Output
    if failed_evaluations:
        output = {"Message": "Some evaluations were not allowed!", "Failures": []}
        for evaluation in failed_evaluations:
            action = evaluation["EvalActionName"]
            resource = evaluation["EvalResourceName"]
            decision = evaluation["EvalDecision"]
            organization = evaluation.get("OrganizationsDecisionDetail", {}).get("AllowedByOrganizations", True)
            msg = f"Failure: Action: {action}, Resource: {resource}, Result: {decision}, AllowedByOrganization: {organization}"
            log.warning(msg)
            output["Failures"].append(
                {
                    "Action": action,
                    "Resource": resource,
                    "Result": decision,
                    "AllowedByOrganizationPolicy": organization,
                }
            )
        return output
    return {"Message": "All evaluations were successful against the Deployment Role"}
