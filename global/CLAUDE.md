# Global rules (my-starter-kit)

These rules apply in every repository. A repo's own `AGENTS.md` / `CLAUDE.md` wins where it is more specific.

## Language

- Write everything in English: code, comments, docs, commit messages, issues, PRs and replies.

## Git flow

- Never commit or push directly to `main`.
- Every change starts from a GitHub issue. If none exists, create one with `gh issue create` before coding.
- Issues carry exactly one `type:*`, one `priority:*`, one or more `area:*` labels, and the milestone of their roadmap step.
- Docs-only changes go in their own PR, never mixed into a code PR.
- Branch name: `<type>/<issue-number>-<short-kebab-desc>` (e.g. `feat/12-add-auth`, `fix/34-null-price`).
- Commits follow Conventional Commits: `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`, `perf:`. Breaking changes use `!` (e.g. `feat!:`).
- Open the PR with `gh pr create`, fill the PR template, and put `Closes #<issue>` in the body.
- PRs are squash-merged, so the PR title must itself be a valid Conventional Commit.
- Open the PR, then stop: merging is the human's decision. Never run `gh pr merge`.

## Quality gate

- New behaviour comes with tests; bug fixes come with a test that failed before the fix.
- Run the repo's lint, type-check and tests locally before opening a PR. Use the commands in the repo's `AGENTS.md`.
- Never open a PR while checks are failing, and never disable or skip a test to make CI pass.
- Run `pre-commit run --all-files` when the repo has a `.pre-commit-config.yaml`.

## Code intelligence

- Before a refactor, rename or change to a shared function, check its impact first (GitNexus `impact` / blast radius) and list the affected callers in the PR.
- Pick the graph tool per repo with `/kit:code-intel`: GitNexus for code-heavy repos, Graphify when docs, PDFs or notes matter as much as code.
- Use Context7 for library and framework docs instead of answering from memory.

## Repo hygiene

- Keep the README selling: one-line pitch, demo or screenshot, quick start, features, then details.
- Keep the GitHub About in sync (`gh repo edit --description ... --add-topic ...`) when the project's scope changes.
- A decision with real trade-offs gets an ADR in `DECISIONS.md`; a contract change updates `AGENTS.md` in the same PR.
- Never commit secrets. Use `.env` (git-ignored) and keep an up-to-date `.env.example`.
- On an empty or bare repository, suggest running `/kit:kickoff` before writing code.
