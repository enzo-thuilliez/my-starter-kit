"""Single entry point for LLM calls.

Every call goes through `complete()` so that the provider (via LiteLLM) and the
tracing (via Langfuse) can change in one place. Local models run through Ollama
(`DEFAULT_MODEL=ollama_chat/<model>`, server at `OLLAMA_API_BASE`). Tracing turns on when the
LANGFUSE_* variables are set and is a no-op otherwise.
"""

from typing import Any

import litellm
from langfuse import observe

from app.config import get_settings


@observe(as_type="generation")
def complete(prompt: str, *, system: str | None = None, model: str | None = None) -> str:
    messages: list[dict[str, Any]] = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    settings = get_settings()
    model_id = model or settings.default_model
    extra: dict[str, Any] = {}
    if model_id.startswith(("ollama/", "ollama_chat/")):
        extra["api_base"] = settings.ollama_api_base

    response = litellm.completion(model=model_id, messages=messages, **extra)
    content = response.choices[0].message.content
    return str(content or "")
