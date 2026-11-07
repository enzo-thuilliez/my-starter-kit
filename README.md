<div align="center">

# my-starter-kit

**Everything in its place before you code.**

My Claude Code setup in one repo: one script installs the agent tooling on a machine,
and one command turns an idea into a repository that is ready for agent-driven work.

[![Claude Code plugin](https://img.shields.io/badge/Claude%20Code-plugin-D97757?style=flat-square)](https://code.claude.com/docs)
[![License: MIT](https://img.shields.io/badge/license-MIT-111?style=flat-square)](LICENSE)
![Stacks](https://img.shields.io/badge/templates-Python%20%7C%20Next.js-111?style=flat-square)

[Why](#why) · [What's inside](#whats-inside) · [Install](#install) · [Kickoff](#kitkickoff) · [Code intel](#kitcode-intel) · [Fork it](#fork-and-customize)

</div>

## Why

I kept starting repos and repeating the same things to my agents: the folder structure, a README
that sells, tests and evals, the About description, and above all the **issue → branch → PR**
flow with CI. This kit writes all of that down once.

It is opinionated and personal. It is public so you can fork it and swap in your own choices.

## How it fits together

```mermaid
flowchart LR
    subgraph machine["Machine — once (install.sh)"]
        plugins["Plugins<br/>workflow skills · Ponytail · Floorplan · kit"]
        intel["Code graphs<br/>GitNexus · Graphify"]
        mcp["MCP<br/>Context7 · Playwright"]
        rules["~/.claude/CLAUDE.md<br/>global rules"]
    end
    subgraph repo["Repo — per project (/kit:kickoff)"]
        tpl["Templates<br/>AGENTS.md · CI · tests · evals"]
        docs["README · About · topics"]
        index["Code-intel index"]
    end
    subgraph gh["GitHub — every change"]
        issue["Issue"] --> branch["Branch"] --> pr["PR<br/>CI · title lint · secret scan"] --> squash["Squash merge"] --> release["release-please"]
    end
    machine --> repo --> gh
```

## What's inside

| Tool | What it does here | Level |
|---|---|---|
| **kit** (this plugin) | `/kit:kickoff` and `/kit:code-intel` | Global |
| [agent-skills](https://github.com/addyosmani/agent-skills) *or* [ECC](https://github.com/affaan-m/ECC) | Engineering workflow skills (spec → plan → test → review → ship). Pick one with `--workflow` | Global |
| [Ponytail](https://github.com/DietrichGebert/ponytail) | Makes the agent write the least code that does the job | Global |
| [Floorplan](https://github.com/haydenschmitty/floorplan) | Human-readable map of an app's architecture, on demand | Global |
| [GitNexus](https://www.npmjs.com/package/gitnexus) | Code graph + impact analysis before changes (MCP, hooks) | Global + per repo |
| [Graphify](https://github.com/safishamsi/graphify) | Graph of code **and** docs, PDFs, images | Global + per repo |
| [Context7](https://github.com/upstash/context7) | Up-to-date library docs in context (MCP) | Global |
| [Playwright MCP](https://github.com/microsoft/playwright-mcp) | Lets the agent drive a real browser to check the UI | Global |
| [ccusage](https://github.com/ryoppippi/ccusage) | Measures token usage, to check what the rest actually saves | Global |
| [promptfoo](https://github.com/promptfoo/promptfoo) | LLM evals, wired into every template | Global + per repo |
| [pre-commit](https://pre-commit.com) | Lint, format and secret checks before each commit | Global + per repo |
| [Langfuse](https://github.com/langfuse/langfuse) | LLM tracing in the templates; self-host with `--with-langfuse` | Per repo |
| [release-please](https://github.com/googleapis/release-please) | Changelog, version and release from Conventional Commits | Per repo |
| [OmniRoute](https://github.com/diegosouzapw/OmniRoute) | Local LLM gateway, opt-in with `--with-omniroute` | Optional |

**Templates** (copied by `/kit:kickoff`):

- `common` — `AGENTS.md` (+ `CLAUDE.md` → `@AGENTS.md`), issue forms (bug, feature, task),
  PR template, labels, CODEOWNERS, Dependabot, CI for PR titles, release-please, gitleaks and
  label sync, CONTRIBUTING, SECURITY, LICENSE, pre-commit.
- `python` — uv, FastAPI, pydantic-settings, LiteLLM + Langfuse LLM layer, Ruff, mypy strict,
  pytest with coverage, promptfoo evals, Dockerfile, CI.
- `typescript` — Next.js (App Router) overlay: Tailwind + shadcn/ui, Biome, Zod env validation,
  Vercel AI SDK (Anthropic + OpenAI) + Langfuse, Vitest, Playwright, promptfoo evals, CI with e2e.
- Both together as a monorepo (`apps/api` + `apps/web`).

## Install

Requirements: Linux or WSL (Ubuntu), Node 22+, [Claude Code](https://code.claude.com/docs),
[GitHub CLI](https://cli.github.com). The script installs the rest (uv, build tools) and asks
for `sudo` only for apt packages.

```bash
git clone https://github.com/enzo-thuilliez/my-starter-kit.git
cd my-starter-kit
./install.sh --dry-run     # see what it would do
./install.sh               # do it
```

Options:

| Flag | Effect |
|---|---|
| `--workflow=agent-skills` | Default workflow layer. Uninstalls ECC if present |
| `--workflow=ecc` | ECC instead, with `ECC_HOOK_PROFILE=minimal`. Uninstalls agent-skills |
| `--with-omniroute` | Install the OmniRoute gateway (Node 22 or 24) |
| `--with-langfuse` | Run a self-hosted Langfuse with Docker on `localhost:3000` |
| `--windows-too` | Print the PowerShell steps for Claude Code on the Windows side |
| `--dry-run` | Print every command, change nothing |

The script is **idempotent**: run it again any time to update everything. Your global rules
go into a delimited block of `~/.claude/CLAUDE.md`; anything else in that file is left alone,
and a `.bak` is kept on every change.

Only want the skills? `claude plugin marketplace add enzo-thuilliez/my-starter-kit && claude plugin install kit@my-starter-kit`.

## `/kit:kickoff`

Run it in an empty folder, an empty GitHub repo, or a repo that already has code.

1. **Detects** where you start. Existing code is never overwritten (retrofit mode).
2. **Interviews** you (10–15 questions: pitch, users, v0.1 features, stack, LLM, data, auth,
   deploy, eval cases) and asks you to **confirm a spec** before touching anything.
3. Opens a **"Bootstrap repository"** issue and a `chore/<n>-bootstrap` branch.
4. **Applies the templates** and scaffolds the stack.
5. Writes **AGENTS.md** for the project and a **selling README**.
6. Gets lint, types and tests **green**, installs pre-commit, runs `/kit:code-intel`.
7. Opens the **bootstrap PR** — you review and merge it.
8. Sets the **About and topics**, squash-only merges, branch auto-delete, labels, and
   **branch protection** on `main` (CI, PR title and secret scan required).
9. Creates a **v0.1 milestone** with one issue per feature.

A Python project ends up like this:

```
my-project/
├── .github/
│   ├── ISSUE_TEMPLATE/        bug · feature · task
│   ├── workflows/             ci · evals · pr-title · release-please · secrets · labels
│   ├── CODEOWNERS  dependabot.yml  labels.yml  pull_request_template.md
├── src/app/                   main.py · config.py · llm.py
├── tests/                     test_api.py · test_llm.py
├── evals/                     promptfooconfig.yaml · provider.py
├── AGENTS.md  CLAUDE.md  README.md  CONTRIBUTING.md  SECURITY.md  LICENSE
├── Dockerfile  pyproject.toml  .pre-commit-config.yaml  .env.example
└── release-please-config.json
```

## `/kit:code-intel`

GitNexus and Graphify overlap, so each repo gets **one** primary graph tool. The skill measures
the repo: mostly code → **GitNexus** (call chains, impact before a refactor); docs, PDFs or
notes that matter as much as code → **Graphify**. It tells you why, indexes, and writes the
"Code intelligence" section of `AGENTS.md`. You can always overrule it.

## Global rules

`global/CLAUDE.md` is what I used to repeat in every session:

- English everywhere.
- Never push to `main`; issue → `type/<n>-desc` branch → PR with `Closes #n`; Conventional Commits; squash.
- The agent opens the PR and stops. Merging is mine.
- Tests with every change, checks green before a PR, never skip a test.
- Impact analysis before refactors, Context7 for library docs.
- Selling README, About in sync, no secrets in git.

## Fork and customize

1. Fork, then replace `enzo-thuilliez/my-starter-kit` in `install.sh` (`REPO=`) and in
   `.claude-plugin/marketplace.json`.
2. Edit `global/CLAUDE.md` — it is your rulebook.
3. Change the tool list in `install.sh` (each step is a small function).
4. Add a stack: create `templates/<stack>/` with its files and a `_kit.md` (scaffold commands,
   AGENTS.md command table, monorepo notes). `/kit:kickoff` reads it.
5. Template rules (see `scripts/apply-template.sh --help`): stack files overwrite `common` ones,
   `*.append` files are appended, `_kit.md` is never copied, only `{{UPPER_CASE}}` variables you
   pass are replaced.

## Contributing

Issues and PRs welcome. The kit follows its own rules: see [AGENTS.md](AGENTS.md).
Before a PR: `claude plugin validate .` and `shellcheck install.sh scripts/*.sh`.

## License

[MIT](LICENSE) © 2026 Enzo Thuilliez. Each tool listed above keeps its own license.
