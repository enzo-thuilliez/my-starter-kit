"""Replays a recorded Anthropic call through the real LLM layer: no network, no cost.

The cassette in `tests/cassettes/test_llm_replay/` was written by hand for the template.
In a project, record real ones with `--record-mode=once` (see `conftest.py`).
"""

import pytest

from app.llm import complete


@pytest.mark.vcr
def test_complete_replays_a_recorded_call(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("ANTHROPIC_API_KEY", "test-key-not-used")
    answer = complete("What is the capital of France?", model="anthropic/claude-sonnet-5-5")
    assert answer == "Paris."
