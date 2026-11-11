"""promptfoo provider that runs prompts through the app's own LLM layer."""

from typing import Any

from app.llm import complete


def call_api(prompt: str, options: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    config = options.get("config", {})
    return {"output": complete(prompt, system=config.get("system"), model=config.get("model"))}
