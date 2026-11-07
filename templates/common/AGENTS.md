# AGENTS.md

Instructions for AI coding agents working on **{{PROJECT_NAME}}**.
Global rules (git flow, quality gate, language) live in `~/.claude/CLAUDE.md`; this file adds what is specific to this repo.

## Project

{{DESCRIPTION}}

<!-- kickoff: 3–6 lines on what the product does, who uses it, and the main moving parts. -->

## Stack

<!-- kickoff: language, framework, package manager, main libraries, LLM providers. -->

## Commands

| Task | Command |
|---|---|
| Install | <!-- kickoff --> |
| Dev server | <!-- kickoff --> |
| Lint + format | <!-- kickoff --> |
| Type-check | <!-- kickoff --> |
| Tests | <!-- kickoff --> |
| Evals | <!-- kickoff --> |

Run lint, type-check and tests before every PR.

## Architecture

<!-- kickoff: folder map with one line per top-level directory. Update when structure changes. -->

## Conventions

<!-- kickoff: naming, error handling, logging/tracing, where tests live, anything an agent would get wrong. -->

## Code intelligence

<!-- kickoff: written by /kit:code-intel — which graph tool this repo uses and how to refresh it. -->

## Out of scope for agents

- Never edit generated files, lockfiles by hand, or `CHANGELOG.md` (release-please owns it).
- Never touch `.github/workflows/` without an issue that asks for it.
