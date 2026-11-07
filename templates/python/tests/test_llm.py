from types import SimpleNamespace
from unittest.mock import patch

from app.llm import complete


def _fake_response(text: str) -> SimpleNamespace:
    message = SimpleNamespace(content=text)
    return SimpleNamespace(choices=[SimpleNamespace(message=message)])


def test_complete_sends_system_and_user_messages() -> None:
    with patch("app.llm.litellm.completion", return_value=_fake_response("hi")) as fake:
        assert complete("hello", system="be brief", model="openai/gpt-4o-mini") == "hi"
    kwargs = fake.call_args.kwargs
    assert kwargs["model"] == "openai/gpt-4o-mini"
    assert kwargs["messages"] == [
        {"role": "system", "content": "be brief"},
        {"role": "user", "content": "hello"},
    ]
