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


def test_local_models_go_to_the_ollama_server() -> None:
    with patch("app.llm.litellm.completion", return_value=_fake_response("ok")) as fake:
        complete("hello", model="ollama_chat/qwen3:8b")
    assert fake.call_args.kwargs["api_base"] == "http://localhost:11434"


def test_hosted_models_get_no_api_base() -> None:
    with patch("app.llm.litellm.completion", return_value=_fake_response("ok")) as fake:
        complete("hello", model="anthropic/claude-sonnet-5-5")
    assert "api_base" not in fake.call_args.kwargs
