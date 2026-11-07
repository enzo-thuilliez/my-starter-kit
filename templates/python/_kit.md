# Python stack — notes for /kit:kickoff

Not copied into the project. Read by the skill.

## After copying

```bash
uv lock && uv sync
uv run pytest            # must pass before the first commit
```

## AGENTS.md values

| Task | Command |
|---|---|
| Install | `uv sync` |
| Dev server | `uv run uvicorn app.main:app --reload` |
| Lint + format | `uv run ruff check --fix . && uv run ruff format .` |
| Type-check | `uv run mypy` |
| Tests | `uv run pytest` |
| Evals | `uv run promptfoo eval -c evals/promptfooconfig.yaml` |

Stack: Python 3.12, uv, FastAPI, pydantic-settings, LiteLLM (provider-agnostic calls), Langfuse (tracing), Ruff, mypy strict, pytest, promptfoo.

Conventions: all LLM calls go through `app.llm.complete()`; config only through `app.config.get_settings()`; tests mock `litellm.completion`, never call a real model.

## Options to drop

- No API: delete `src/app/main.py`, `tests/test_api.py`, fastapi/uvicorn deps and the Dockerfile CMD.
- No LLM: delete `src/app/llm.py`, `tests/test_llm.py`, `evals/`, `evals.yml`, litellm/langfuse deps.

## Monorepo (apps/api)

Copy into `apps/api/`, then in `ci.yml` and `evals.yml` add `defaults.run.working-directory: apps/api`,
set `on.pull_request.paths: [apps/api/**]`, and in `dependabot.yml` set `directory: /apps/api` for `uv`.
In `release-please-config.json` use the key `apps/api`.
