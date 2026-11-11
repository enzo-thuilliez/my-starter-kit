@AGENTS.md

## Claude Code notes

- `.claude/settings.json` lets agents run the project's build, test and git commands, push
  `feat/`, `fix/`, `chore/`... branches and open issues and PRs. Pushes to `main`, force pushes,
  `gh pr merge` and `rm -rf` are denied.
- Hooks in `.claude/hooks/`: `protect-secrets.sh` blocks reading or writing `.env` files,
  private keys and credential files; `after-edit.sh` formats and lints each edited file and runs
  its related tests, and sends any failure back to the agent. Set `KIT_HOOKS_OFF=1` to skip both.
- Project settings and hooks only load once the workspace is trusted: run `claude` in the repo
  and accept the trust dialog.
