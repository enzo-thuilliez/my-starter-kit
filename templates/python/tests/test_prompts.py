from pathlib import Path

import pytest

from app.prompts import PROMPTS_DIR, PromptError, render_prompt


def test_render_fills_placeholders() -> None:
    text = render_prompt("ask", version=1, question="What is 2 + 2?")
    assert "What is 2 + 2?" in text
    assert "{{" not in text


def test_missing_variable_is_an_error() -> None:
    with pytest.raises(PromptError, match="question"):
        render_prompt("ask", version=1)


def test_unknown_version_is_an_error() -> None:
    with pytest.raises(PromptError, match="version 999"):
        render_prompt("ask", version=999, question="x")


@pytest.mark.parametrize("path", sorted(PROMPTS_DIR.glob("*/*.md")), ids=lambda p: p.name)
def test_prompt_files_are_named_by_version(path: Path) -> None:
    assert path.stem.startswith("v"), f"{path} must be named v<N>.md"
    assert path.stem[1:].isdigit(), f"{path} must be named v<N>.md"
