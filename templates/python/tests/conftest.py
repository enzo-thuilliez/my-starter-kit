"""Shared test configuration.

Recorded LLM and HTTP calls (pytest-recording, VCR.py): a test marked `@pytest.mark.vcr`
replays its cassette from `tests/cassettes/<module>/<test>.yaml` and never reaches the
network. To record or refresh one, run it once with real keys:

    uv run pytest tests/test_x.py --record-mode=once

Credentials are stripped from the recorded requests (`filter_headers` below). Read every new
cassette before committing it: a response body can still echo data you did not mean to keep.
"""

from typing import Any

import pytest


@pytest.fixture(scope="module")
def vcr_config() -> dict[str, Any]:
    return {
        "filter_headers": [
            "authorization",
            "x-api-key",
            "api-key",
            "openai-organization",
            "cookie",
            "set-cookie",
        ],
        "decode_compressed_response": True,
    }
