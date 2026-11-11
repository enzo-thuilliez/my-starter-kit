"""Export the API contract: `uv run python -m app.schema` writes `openapi.json`.

The file is committed. `tests/test_schema.py` fails when it no longer matches the code, so
every API change shows up in the PR diff, and a TypeScript client generated from it
(openapi-typescript, see the kit notes) cannot drift silently.
"""

import json
import sys
from pathlib import Path

from app.main import app

DEFAULT_PATH = Path("openapi.json")


def render() -> str:
    return json.dumps(app.openapi(), indent=2, sort_keys=True) + "\n"


def main(argv: list[str]) -> int:
    path = Path(argv[0]) if argv else DEFAULT_PATH
    path.write_text(render(), encoding="utf-8")
    print(f"wrote {path}")
    return 0


if __name__ == "__main__":  # pragma: no cover
    raise SystemExit(main(sys.argv[1:]))
