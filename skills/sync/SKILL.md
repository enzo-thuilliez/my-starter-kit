---
name: sync
description: Bring an existing repo up to date with the current kit templates (CI, hooks, settings, dev container, tooling config) without overwriting what the project changed on purpose, through issues and PRs. Use when the user runs /kit:sync, after the kit's templates changed, or when /kit:audit reports missing kit files or drift.
---

# Sync a repo with the kit templates

Templates are applied once at kickoff; the kit keeps improving afterwards. This skill finds
what changed and ports it, file by file, through the repo's own issue → PR workflow.

## 1. Audit first

Run `/kit:audit` on the repo. Fix nothing yet; it tells you which drifts matter (settings,
labels, ROADMAP) that are not template files.

## 2. Compare with the templates

Work in an up-to-date clone of the default branch. Reconstruct the `apply-template.sh`
arguments the repo was created with:

- **Stacks**: `pyproject.toml` → `python`; `package.json` with `next` → `typescript`;
  `Cargo.toml` → `rust`; `apps/api` + `apps/web` → monorepo (`--subdir apps/api --stack python
  --subdir apps/web --stack typescript`); `scripts/denylist-check.sh` → add `--stack privacy`.
  Always start with `--stack common`.
- **Variables**: `PROJECT_NAME` (repo name), `DESCRIPTION` (GitHub About), `OWNER`,
  `AUTHOR` and `YEAR` (from `LICENSE`), `CRATE_NAME` for Rust.

```bash
$KIT/scripts/sync.sh --target <clone> --stack common --stack <stack> --var PROJECT_NAME=... \
  --var "DESCRIPTION=..." --var OWNER=... --var "AUTHOR=..." --var YEAR=... [--diff]
```

It reports each kit-managed file as **missing**, **identical** or **differs**, and checks that
every kit `.gitignore` entry is present. Project files (README, AGENTS.md, source, tests,
manifests) are never compared.

## 3. Decide, file by file

- **missing**: add it, unless the project deliberately does without it (for example a release
  workflow on a project with releases off, or a tool the AGENTS.md says it replaced). Ask when
  unsure.
- **differs**: read the diff (`--diff`). Port the kit's improvements (a new check, a fixed
  pin, a safer setting) into the repo's file and keep everything the project added on purpose
  (extra jobs, its own labels, different matrix). Never replace a project file wholesale.
- **identical**: nothing to do.
- Monorepo: kickoff merged `ci-<subdir>.yml` into one `ci.yml`, so they show as missing.
  Compare their jobs with the matching jobs in `ci.yml` instead of adding the files.
- New CI jobs go behind `ci-pass`, so branch protection still needs one check.

## 4. Ship it

Follow the target repo's AGENTS.md (branch names, labels, scopes, CHANGELOG rule).

- One issue and one PR per kind of change: CI and workflows; agent tooling (hooks,
  `.claude/settings.json`, dev container); docs. Docs never share a PR with code.
- PR body: what the kit changed, what was kept from the project and why.
- Run the repo's own lint, type-check and tests before pushing. Never merge.
- Repository settings found by the audit go to the user as commands.

## 5. Report

The PRs opened, the files left different on purpose (and why), and the owner commands.
