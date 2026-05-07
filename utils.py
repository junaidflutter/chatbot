from datetime import datetime
import json
from constants import (
    JSON_INDENT,
    LOG_HEADER_TEMPLATE,
    MESSAGE_KEY,
    ROLE_KEY,
    TIMESTAMP_FORMAT,
    TIMESTAMP_KEY,
)


def format_as_json(role: str, content: str) -> dict:
    return {
        TIMESTAMP_KEY: datetime.now().strftime(TIMESTAMP_FORMAT),
        ROLE_KEY: role,
        MESSAGE_KEY: content,
    }


def log_json(label: str, data: dict):
    print(LOG_HEADER_TEMPLATE.format(label=label))
    print(json.dumps(data, indent=JSON_INDENT, ensure_ascii=False))
