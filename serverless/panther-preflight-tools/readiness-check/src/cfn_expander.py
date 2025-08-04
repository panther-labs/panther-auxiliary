# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.
"""
Utilities for fetching, formatting, and expanding policies residing in a role
"""

from typing import Dict, List
import boto3

from policyuniverse.expander_minimizer import _expand_wildcard_action


def resolve_policy_statement_resources(policy: Dict) -> None:
    """
    Mutates a given policy;
    Unifies Resource and NotResource fields to lists
    """

    def _normalize_resource_value(resources: list[str] | str) -> List[str]:
        # Helper to normalize a str or list into a list
        return resources if isinstance(resources, list) else [resources] if isinstance(resources, str) else []

    for statement in policy["Statement"]:
        resource_key = (
            "Resource" if statement.get("Resource") else "NotResource" if statement.get("NotResource") else None
        )

        if resource_key:
            statement[resource_key] = _normalize_resource_value(statement.get(resource_key))


def expand_policy_statement_actions(policy: Dict) -> None:
    """
    Mutates a given policy;
    Expanding all wildcard actions defined in statements to a list of discrete actions
    """
    for statement in policy["Statement"]:
        actions_list = []
        if isinstance(statement.get("Action"), list):
            for action in statement.get("Action"):
                expanded_actions = _expand_wildcard_action(action)
                actions_list.extend(expanded_actions)
        else:
            actions_list.extend(_expand_wildcard_action(statement.get("Action")))
        statement["Action"] = actions_list


def get_deployment_role_policies(role_name: str = "PantherDeploymentRole") -> List[Dict]:
    """
    Fetches the policies from the deployment role existing in the account
    """
    client = boto3.client("iam")
    # Collect the policy docs for inline policies
    inline_policy_names = client.list_role_policies(RoleName=role_name).get("PolicyNames", [])
    inline_policydocs = list(
        map(
            lambda p: client.get_role_policy(RoleName=role_name, PolicyName=p).get("PolicyDocument", "{}"),
            inline_policy_names,
        )
    )

    # Collect the policy docs for attached managed policies
    attached_policy_arns = list(
        map(
            lambda p: p.get("PolicyArn", ""),
            client.list_attached_role_policies(RoleName=role_name).get("AttachedPolicies", []),
        )
    )
    attached_policydocs = list(
        map(
            lambda q: client.get_policy_version(VersionId=q.get("DefaultVersionId"), PolicyArn=q.get("Arn"))
            .get("PolicyVersion", {})
            .get("Document"),
            map(lambda p: client.get_policy(PolicyArn=p).get("Policy", {}), attached_policy_arns),
        )
    )

    # Assemble them together and unify the resource fields.
    policydocs = inline_policydocs + attached_policydocs
    for policydoc in policydocs:
        resolve_policy_statement_resources(policydoc)
    return policydocs


def get_deployment_role_policies_with_expanded_actions(role_name: str = "PantherDeploymentRole") -> Dict:
    """
    Fetches the policies from the deployment role existing in the account
    Expands actions from wildcards into discrete actions
    """
    policydocs = get_deployment_role_policies(role_name=role_name)
    for policydoc in policydocs:
        expand_policy_statement_actions(policydoc)
    return policydocs
