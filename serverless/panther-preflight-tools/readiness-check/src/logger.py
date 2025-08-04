# Copyright (C) 2022 Panther Labs, Inc.
#
# The Panther SaaS is licensed under the terms of the Panther Enterprise Subscription
# Agreement available at https://panther.com/enterprise-subscription-agreement/.
# All intellectual property rights in and to the Panther SaaS, including any and all
# rights to access the Panther SaaS, are governed by the Panther Enterprise Subscription Agreement.
"""
Shared logger configuration for the readiness check tools
"""

import logging


def get_logger(name="readiness-checker", level=logging.INFO):
    """
    Configure and return a logger with the specified name and level.

    Args:
        name: The name of the logger
        level: The logging level to set

    Returns:
        A configured logger instance
    """
    logger = logging.getLogger(name)

    # Only add handler if the logger doesn't already have handlers
    # This prevents duplicate log messages when the module is imported multiple times
    if not logger.handlers:
        logger.setLevel(level)
        handler = logging.StreamHandler()
        handler.setLevel(level)
        logger.addHandler(handler)

    return logger


# Pre-configured logger for backward compatibility
log = get_logger()
