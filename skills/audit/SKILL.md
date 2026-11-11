---
name: audit
description: Check an existing GitHub repo against the kit conventions (merge settings, protection of main, labels, labelled issues, kit files, actions pinned by SHA, ROADMAP in sync with issues, English only, CI and Dependabot) and report pass, warn and fail with fixes. Use when the user runs /kit:audit, asks whether a repo is "clean", "up to date" or "consistent", or before /kit:sync.
---

# Audit a repository

Read-only. The script does the checks; you interpret them and turn failures into fixes the
user can act on.

## 1. Run the checks

```bash
KIT=<kit root>        # the folder that holds scripts/audit.sh
git -C <clone> fetch origin && git -C <clone> checkout <default branch> && git -C <clone> pull --ff-only
$KIT/scripts/audit.sh <owner>/<repo> <clone>
```

- Pass a clone that is up to date with the default branch: the pinning, ROADMAP and language
  checks read files from it, and the script warns when it is stale.
- Without a clone, the file checks go through the API and the local checks are skipped.
- Branch protection needs admin read access. "Missing required check" can also mean the token
  cannot see protection: say so instead of claiming the repo is unprotected.
- Several repos: run it once per repo and give one table per repo.

## 2. Report

Show only what is not PASS, then one line per repo that is fully green. For each FAIL, say
why it matters in a few words and give the fix:

| Finding | Fix |
|---|---|
| Merge settings, protection, topics, default branch | The commands printed under "Commands for the owner". Give them as single-line commands (no heredoc: a copy with indented lines breaks it). Repository settings are the owner's to change. |
| Open issues without `type:*` / `priority:*` | Propose labels from each title (`feat:` → `type:feat`) and the milestone; apply them with `gh api` once the user agrees. |
| Missing kit files, unpinned actions | `/kit:sync` (or one PR per kind of change). |
| ROADMAP out of sync | A small docs PR ticking or unticking the lines, with its issue. |
| CI red on the default branch | Read the failing run's log before proposing anything. |
| Dependabot PR with failing CI | Do not merge it. Either fix the code for the new version, or ignore that update in `.github/dependabot.yml`. |
| WARN "English only" | Fine when intended (a UI glossary, a domain term). Otherwise translate. |

## 3. Rules

- Never change a repository setting, merge, close or delete anything during an audit.
- Fixes to files go through the repo's own workflow: issue → branch → PR, docs-only changes in
  their own PR, following its AGENTS.md.
