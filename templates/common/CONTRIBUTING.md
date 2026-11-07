# Contributing to {{PROJECT_NAME}}

Thanks for helping out! The flow is the same for humans and AI agents.

1. **Open an issue** (bug, feature or task template) or pick an existing one.
2. **Create a branch** named `<type>/<issue>-<short-desc>`, e.g. `feat/12-add-auth`.
3. **Commit** with [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`, `ci:`.
4. **Check locally**: lint, type-check and tests must pass (see the commands in `AGENTS.md`). `pre-commit install` runs the basics on every commit.
5. **Open a pull request** using the template, with `Closes #<issue>` in the body. The PR title must be a Conventional Commit: PRs are squash-merged and the title becomes the commit on `main`.
6. A maintainer reviews and merges. Releases and the changelog are automated by release-please.

## Reporting security issues

Please don't open a public issue. See [SECURITY.md](SECURITY.md).
