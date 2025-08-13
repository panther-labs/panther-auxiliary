# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

from src import cfn_expander
import json
from copy import deepcopy

with open("test/example_policy.json", "r") as file:
    test_policy = json.loads(file.read())


def test_resolve_policy_statement_resources() -> None:
    local_policy = deepcopy(test_policy)
    cfn_expander.resolve_policy_statement_resources(local_policy)

    for statement in local_policy.get("Statement"):
        resources = statement.get("Resource", None)
        if not resources:
            resources = statement.get("NotResource")
        assert isinstance(resources, list)
    return


def test_expand_policy_statement_actions() -> None:
    local_policy = deepcopy(test_policy)
    cfn_expander.expand_policy_statement_actions(local_policy)

    for statement in local_policy.get("Statement"):
        actions = statement.get("Action")
        for action in actions:
            assert "*" not in action
    return
