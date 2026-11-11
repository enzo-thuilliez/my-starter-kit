"""Versioned prompts, kept out of the code.

Each prompt lives in `prompts/<name>/v<N>.md` next to this file, with plain `{{var}}`
placeholders (no logic, so promptfoo renders the same files). Versions are immutable: to
change a prompt, add `v<N+1>.md`, evaluate it against the current one with promptfoo, then
bump the version where the prompt is used.
"""

import re
from functools import cache
from pathlib import Path

PROMPTS_DIR = Path(__file__).parent
_PLACEHOLDER = re.compile(r"\{\{\s*(\w+)\s*\}\}")


class PromptError(ValueError):
    """Raised for an unknown prompt, version or variable."""


@cache
def load_prompt(name: str, version: int) -> str:
    path = PROMPTS_DIR / name / f"v{version}.md"
    if not path.is_file():
        msg = f"No prompt {name!r} version {version} (expected {path})"
        raise PromptError(msg)
    return path.read_text(encoding="utf-8")


def render_prompt(name: str, version: int, **variables: str) -> str:
    template = load_prompt(name, version)
    missing = sorted({m.group(1) for m in _PLACEHOLDER.finditer(template)} - variables.keys())
    if missing:
        msg = f"Prompt {name!r} v{version} needs {', '.join(missing)}"
        raise PromptError(msg)
    return _PLACEHOLDER.sub(lambda m: variables[m.group(1)], template)
