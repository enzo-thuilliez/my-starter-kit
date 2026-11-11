from pathlib import Path

from app.schema import main, render

COMMITTED = Path(__file__).resolve().parents[1] / "openapi.json"


def test_committed_schema_matches_the_code() -> None:
    assert COMMITTED.is_file(), "openapi.json is missing: run `uv run python -m app.schema`"
    assert COMMITTED.read_text(encoding="utf-8") == render(), (
        "The API changed: run `uv run python -m app.schema` and commit openapi.json"
    )


def test_main_writes_the_schema(tmp_path: Path) -> None:
    target = tmp_path / "openapi.json"
    assert main([str(target)]) == 0
    assert target.read_text(encoding="utf-8") == render()
