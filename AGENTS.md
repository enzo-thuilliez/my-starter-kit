# AGENTS.md

Instructions for AI coding agents working **on this repository** (the kit itself).

## What this repo is

`my-starter-kit` is a Claude Code plugin marketplace with one plugin, `kit`:

- `install.sh` — idempotent machine setup (plugins, MCP servers, CLIs).
- `scripts/apply-template.sh` — copies templates into a project (used by `/kit:kickoff`).
- `scripts/audit.sh` — read-only check of a repo against the conventions (used by `/kit:audit`).
- `global/CLAUDE.md` — cross-project rules installed into `~/.claude/CLAUDE.md`.
- `skills/` — plugin skills (`/kit:kickoff`, `/kit:audit`, `/kit:code-intel`).
- `templates/common/` — files copied into every new repo.
- `templates/<stack>/` — stack-specific files (`python`, `typescript`, `rust`), plus the
  opt-in `privacy` overlay for projects that handle real data.

## Rules

- Everything user-facing is written in **English**.
- `install.sh` must stay **idempotent**: running it twice changes nothing the second time.
- Every change goes through an issue → branch → PR. PRs are **squash-merged**.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/)
  (`feat:`, `fix:`, `docs:`, `chore:`…): release-please builds the changelog from them.
- Templates are copied verbatim into other repos: keep placeholders as `{{PROJECT_NAME}}`,
  `{{DESCRIPTION}}`, `{{OWNER}}`, `{{AUTHOR}}`, `{{YEAR}}`, `{{CRATE_NAME}}` (Rust), and never hard-code this repo's name inside them.

## Checks before opening a PR

```bash
claude plugin validate .
shellcheck install.sh scripts/*.sh templates/common/.claude/hooks/*.sh templates/common/.devcontainer/*.sh templates/privacy/scripts/*.sh
```
