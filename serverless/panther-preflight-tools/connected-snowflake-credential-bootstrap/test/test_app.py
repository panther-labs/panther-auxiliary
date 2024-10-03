# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.

from pytest import mark
from src import app

BASE_EVENT = {"user": "PANTHERACCOUNTADMIN"}


@mark.parametrize(
    "event,valid",
    [
        [{"asdfasdf": "asdfasdf"}, False],
        [{"user": "test"}, False],
        [{"host": "test"}, False],
        [{"user": "PANTHERACCOUNTADMIN", "host": "ryan.snowflakecomputing.com"}, True],
    ],
)
def test_parse_event_into_creds_validation_exception(event: dict[str, str], valid: bool) -> None:
    try:
        app.parse_event_into_creds(event)
    except:
        assert not valid
        return

    assert valid
    return


@mark.parametrize(
    "event,expected_host",
    [
        [BASE_EVENT | {"host": "ryan.snowflakecomputing.com"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "//ryan.snowflakecomputing.com"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "http://ryan.snowflakecomputing.com"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "https://ryan.snowflakecomputing.com"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "snowflake://ryan.snowflakecomputing.com"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "https://ryan.snowflakecomputing.com/"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "https://ryan.snowflakecomputing.com/login"}, "ryan.snowflakecomputing.com"],
        [BASE_EVENT | {"host": "pantherlabs-ryan.snowflakecomputing.com"}, "pantherlabs-ryan.snowflakecomputing.com"],
    ],
)
def test_parse_event_into_creds_host(event: dict[str, str], expected_host: str) -> None:
    creds = app.parse_event_into_creds(event)
    assert creds.host == expected_host


@mark.parametrize(
    "event,expected_account",
    [
        [BASE_EVENT | {"host": "ryan.snowflakecomputing.com"}, "ryan"],
        [BASE_EVENT | {"host": "https://ryan.snowflakecomputing.com/login"}, "ryan"],
        [BASE_EVENT | {"host": "pantherlabs-ryan.snowflakecomputing.com"}, "pantherlabs-ryan"],
        [BASE_EVENT | {"host": "pantherlabs-ryan_clone.snowflakecomputing.com"}, "pantherlabs-ryan_clone"],
    ],
)
def test_parse_event_into_creds_account(event: dict[str, str], expected_account: str) -> None:
    creds = app.parse_event_into_creds(event)
    assert creds.account == expected_account
