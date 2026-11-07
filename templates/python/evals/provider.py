"""promptfoo provider that runs prompts through the app's own LLM layer."""

from typing import Any

from app.llm import complete


def call_api(prompt: str, options: dict[str, Any], context: dict[str, Any]) -> dict[str, Any]:
    model = options.get("config", {}).get("model")
    return {"output": complete(prompt, model=model)}
