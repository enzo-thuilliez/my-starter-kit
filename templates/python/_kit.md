# Python stack — notes for /kit:kickoff

Not copied into the project. Read by the skill.

## After copying

```bash
uv lock && uv sync
uv run python -m app.schema   # writes openapi.json (committed; a test checks it matches the code)
uv run pytest                 # must pass before the first commit
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
| API schema | `uv run python -m app.schema` (after any API change) |

Stack: Python 3.12, uv, FastAPI, pydantic-settings, LiteLLM (provider-agnostic calls), Langfuse (tracing), Ruff, mypy strict, pytest, promptfoo.

Testing: unit tests mock `litellm.completion`; `tests/test_llm_replay.py` shows the other way,
replaying a recorded call (pytest-recording / VCR.py, cassettes in `tests/cassettes/`, record
with `--record-mode=once`, credentials stripped by `conftest.py`). Invariants get Hypothesis
property tests (`tests/test_guardrails_properties.py`): weights summing to 1, a risk figure never
negative, a parser reading back what a formatter wrote.

Numbers from data: any answer the LLM builds from data goes through
`app.guardrails.enforce_numbers(answer, data)` before it reaches a user or a document. It blocks
(or, with `mode="flag"`, reports) every number that is not in the data, once rounded as written.
Derived figures (sums, ratios) are computed in code and passed in as data. The eval
`evals/assert_numbers.py` applies the same check.

Eval gate: `evals.yml` runs the promptfoo suite on PRs that touch the prompts, the LLM layer
or the evals, compares it with the last run on `main` (kept as the `eval-baseline` artifact)
and posts the result on the PR. It fails when the pass rate drops by more than `EVAL_MAX_DROP`
or a run costs more than `EVAL_MAX_COST_USD` (both set in the workflow). It is a separate check
from `ci-pass` on purpose: it only runs on some PRs and needs an API key, so making it a
required check would block every other PR.

Red team: `evals/redteam.yaml` is a fixed prompt-injection suite (instruction and role
override, injection hidden in user data, fake authority, exfiltration by encoding, by link and
by translation). A canary code in the system prompt must never leak. The `redteam.yml` workflow
runs it by hand and on PRs that touch the prompts or the LLM layer, and skips without an API key.
For generated attacks on top, `promptfoo redteam init` builds a larger plan; check its data
settings first, as some plugins generate attacks through promptfoo's hosted service.

Prompt management: the files are the source of truth. If the project uses Langfuse prompt
management instead, keep one loader in `app/prompts` so the code never cares where a prompt
comes from.

Security checks: CI runs `pip-audit` on the locked dependencies (job `audit`, part of
`ci-pass`); Ruff's `S` rules already cover what Bandit checks. For deeper static analysis, add
Semgrep (`uvx semgrep scan --config auto --error`) as a step in the same job.

Conventions: all LLM calls go through `app.llm.complete()`; prompts live in
`src/app/prompts/<name>/v<N>.md` and are rendered with `app.prompts.render_prompt()` (never inline
in code; a change is a new version file, evaluated by promptfoo before the code switches to it); config only through `app.config.get_settings()`; tests mock `litellm.completion`, never call a real model.

## Options to drop

- No API: delete `src/app/main.py`, `src/app/schema.py`, `tests/test_api.py`, `tests/test_schema.py`, fastapi/uvicorn deps and the Dockerfile CMD.
- No LLM: delete `src/app/llm.py`, `tests/test_llm.py`, `evals/`, `evals.yml`, `redteam.yml`, `.github/scripts/eval-gate.mjs`, litellm/langfuse deps.

## Monorepo (apps/api)

Copy into `apps/api/`, then in `ci.yml` and `evals.yml` add `defaults.run.working-directory: apps/api`,
set `on.pull_request.paths: [apps/api/**]`, and in `dependabot.yml` set `directory: /apps/api` for `uv`.
In `release-please-config.json` use the key `apps/api`.
In a Python + TypeScript monorepo the root `.devcontainer/devcontainer.json` comes from this
stack (Python image with Node); the TypeScript one is skipped, which is expected.
In a monorepo, prefix the `paths:` filters of `evals.yml` and `redteam.yml` with `apps/api/`.
