---
name: kickoff
description: Bootstrap a GitHub repository the kit way — a short clickable interview, structure, AGENTS.md, selling README, CI, issue/PR flow, branch protection, first issues and code-intel indexing. Use when the user runs /kit:kickoff, starts a new project or repo, or wants to retrofit an existing repo with the kit's conventions.
---

# Kickoff

Turn an idea (or an existing repo) into a repository that is ready for agent-driven work:
structured, documented, tested, with an issue → branch → PR flow enforced on GitHub.

Everything written into the repo is in **English**. Talk to the user in the language they use.

## Where things are

The kit root is two directories above this `SKILL.md` (`<kit>/skills/kickoff/SKILL.md`).

- `<kit>/scripts/apply-template.sh` copies templates. Run it with `--help` once to see the rules.
- `<kit>/templates/common/` goes into every repo.
- `<kit>/templates/python/`, `<kit>/templates/typescript/` and `<kit>/templates/rust/` are the stacks. Read the stack's
  `_kit.md` before applying it: it has the scaffold commands, the AGENTS.md command table,
  and the monorepo adjustments.

## 1. Detect the starting point

Run these and decide which mode you are in. Do not ask the user what you can detect.

```bash
git rev-parse --is-inside-work-tree 2>/dev/null
gh repo view --json nameWithOwner,isEmpty,description,url 2>/dev/null
git log --oneline -1 2>/dev/null
ls -A
```

| Mode | Signal | What changes |
|---|---|---|
| **new** | No git repo, or no GitHub remote | Create the GitHub repo (public) in step 4 |
| **empty** | GitHub repo exists, no commits | Push an initial commit in step 4 |
| **retrofit** | Repo already has code | Never overwrite: `--no-clobber`, merge conflicts by hand, no scaffolding |

In **retrofit** mode, first read the existing README, manifests (`pyproject.toml`, `package.json`),
CI and folder layout, so your questions skip what the code already answers.

## 2. Interview: one sentence, two rounds of buttons, one spec

Keep it short and clickable. Never ask an open question through the question tool, and never
dump a long list of items as text: both failed in real runs.

1. **One open question, in plain text** (not the question tool): "Describe the project in one
   or two sentences: what it does and for whom." Skip it if the conversation or, in retrofit
   mode, the README already says. Accept any language; everything written into the repo is
   still English.

2. **Round 1 — question tool, four questions.** Infer every option from the description. The
   first option of each question is your best guess, labelled `(Recommended)`; the user can
   always type their own answer.
   - **Name**: three kebab-case names, each with its one-line pitch in the description.
   - **v0.1 features** (`multiSelect`): the 3–4 features most likely needed, all meant to be
     ticked; the user unticks or adds via Other.
   - **Stack**: Python (FastAPI) / TypeScript (Next.js) / Rust (CLI or library) / Python +
     TypeScript monorepo. Pre-select from the description.
   - **LLM**: the concrete choice (e.g. "Anthropic, claude-sonnet-5-5") / several providers /
     none.

3. **Round 2 — question tool, four questions.**
   - **Deployment**: the likely target first (Vercel for Next.js, Docker for APIs, none for CLIs).
   - **Visibility**: public (Recommended) / private.
   - **Evals**: "These cases: …" with 2–3 inferred cases in the description / "Later" / "None".
   - **Admin bypass** on `main` protection: yes (Recommended) / rules apply to everyone.
   Replace a question by a more useful one when the description leaves something genuinely
   ambiguous (data store, auth provider), and infer the one you dropped.

4. **Infer the rest without asking**: target user, out of scope, data, auth, README visuals,
   5–8 GitHub topics, and agent pitfalls (secrets, model ids, what tests must mock).

5. **Final spec** as a compact two-column table (keep cells short so it renders in a terminal),
   then: "Reply `go` to create everything, or tell me what to change." Create nothing before
   `go`.

If the user is not there to answer, take the recommended options and list them at the top of
the report.

## 3. Pre-flight

```bash
gh auth status
git config user.email
```

If `git config user.email` is a private address GitHub may reject pushes
("push declined due to email privacy restrictions"). Use the noreply address:
`gh api user --jq '"\(.id)+\(.login)@users.noreply.github.com"'`, set it with `git config user.email`.

Some environments block GitHub GraphQL. When a `gh issue create` / `gh pr create` /
`gh repo edit` call fails with a GraphQL error, use the REST equivalent with `gh api`
(examples in step 8).

## 4. Repository and first commit

- **new**: `gh repo create <owner>/<name> --<public|private> --description "<pitch>"` (visibility answer), then clone it or
  `git init && git remote add origin ...` in the current folder.
- **new** and **empty**: commit a minimal `README.md` (title + pitch), the license and
  `.github/workflows/pr-title.yml` from `templates/common` on `main` (`chore: initial commit`)
  and push. This is the only direct commit to `main`. The PR-title check runs on
  `pull_request_target`, which uses the workflow on `main`: without it there, the required
  `conventional` check never reports and the bootstrap PR stays blocked.
- **retrofit**: nothing here.

## 5. Bootstrap issue and branch

Create the issue **"Bootstrap repository"** (Task template fields: goal + checklist of what
this skill will add). Branch: `chore/<issue>-bootstrap`.

## 6. Apply templates and scaffold

Variables: `PROJECT_NAME`, `DESCRIPTION` (pitch), `OWNER` (GitHub login), `AUTHOR`
(git user.name), `YEAR`.

```bash
KIT=<kit root>
VARS=(--var PROJECT_NAME=<name> --var "DESCRIPTION=<pitch>" --var OWNER=<login> \
      --var "AUTHOR=<name>" --var YEAR=$(date +%Y))

# single stack
$KIT/scripts/apply-template.sh --target . --stack common --stack <python|typescript|rust> "${VARS[@]}"
# Rust also needs --var CRATE_NAME=<name with - replaced by _>
# monorepo
$KIT/scripts/apply-template.sh --target . --stack common \
  --subdir apps/api --stack python --subdir apps/web --stack typescript "${VARS[@]}"
# retrofit: add --no-clobber
```

Then:

- **TypeScript**: the stack is an overlay on create-next-app. Order: apply `--stack common`
  alone, run the scaffold commands from `templates/typescript/_kit.md`, then apply
  `--stack typescript` (in a monorepo, run the scaffold inside `apps/web`), then merge the
  `package.json` scripts listed in `_kit.md`.
- **Python**: `uv lock && uv sync`.
- **Monorepo**: apply the "Monorepo" notes from both `_kit.md` files (working directories,
  path filters). Merge `ci-api.yml` and `ci-web.yml` into one `ci.yml` (rename jobs `api` and
  `web`) with a single `ci-pass` that needs both, so protection keeps one check. Merge `.github/dependabot.yml` by hand (one entry per ecosystem and directory),
  and move `release-please-config.json` / `.release-please-manifest.json` to the root with one
  package per app.
- **Retrofit**: for every file the script reports as skipped, merge what is missing into the
  existing file by hand. Never rewrite the project's own code or config wholesale.
- Remove the options the spec ruled out (no LLM → see "Options to drop" in `_kit.md`).
- Add what the spec asked for that templates don't cover (database client, auth) only
  as dependencies + one minimal wiring file with a test; the features themselves are issues.

## 7. Write the docs

**DECISIONS.md** — write ADR-001 for the stack choice (and one per other real trade-off the
spec surfaced).

**AGENTS.md** — fill every `<!-- kickoff ... -->` marker: project summary, stack, the command
table from `_kit.md`, folder map, conventions (including the user's answer to question 13).
Leave no marker and no `{{PLACEHOLDER}}` behind.

**README.md** — selling, in this order:

1. Centered header, the same in all repos: `<div align="center">`, `# Title`, the pitch in
   bold, a badge row (CI, license, release once releases are on, one or two stack badges in
   `style=flat-square&color=111`), a nav line of anchor links, `</div>`. Then a one-line
   `> **Status:** …` quote.
2. Screenshot/GIF placeholder line (`<!-- screenshot: add after first UI -->`) if visual.
3. **Why** — the problem, two or three sentences.
4. **Features** — the v0.1 features, marked planned until built.
5. **Quick start** — clone, `.env` from `.env.example`, install, run. Commands must work.
6. **How it works** — a short mermaid diagram of the main moving parts.
7. **Development** — link to `AGENTS.md` and `CONTRIBUTING.md`, test/lint commands.
8. **License**.

## 8. Verify, index, open the PR

1. Run the stack's lint, type-check and tests. Everything must pass. Fix, don't skip.
2. `pre-commit install && pre-commit run --all-files` (commit any auto-fixes). This installs
   the commit-msg hook too, so non-conventional commit messages are rejected locally.
   `.claude/settings.json` only loads once the user runs `claude` in the repo and trusts it;
   mention that in the report.
3. Run `/kit:code-intel` (or follow its SKILL.md) to pick and index the code graph tool and
   write the "Code intelligence" section of AGENTS.md.
4. Commit in logical Conventional Commits (`chore: add repo template`, `feat: scaffold <stack> app`,
   `docs: write README and AGENTS.md`), push, open the PR titled `chore: bootstrap repository`
   with `Closes #<issue>` and the PR template filled.

REST fallbacks:

```bash
gh api repos/OWNER/REPO/issues -f title="..." -F body=@body.md --jq .number
gh api repos/OWNER/REPO/pulls -f title="..." -f head=BRANCH -f base=main -F body=@body.md --jq .html_url
```

## 9. GitHub settings

```bash
# About + topics
gh api -X PATCH repos/OWNER/REPO -f description="<pitch>"
gh api -X PUT repos/OWNER/REPO/topics -f "names[]=topic1" -f "names[]=topic2"

# Let workflows open PRs (release-please needs it, otherwise the Release workflow fails)
gh api -X PUT repos/OWNER/REPO/actions/permissions/workflow \
  -f default_workflow_permissions=read -F can_approve_pull_request_reviews=true

# Squash only, PR title as commit title, delete merged branches
gh api -X PATCH repos/OWNER/REPO \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY

# Labels now (the label-sync workflow only runs once merged on main). First add the
# project's area:* labels to .github/labels.yml (one per top-level module or concern,
# e.g. area:backend, area:frontend, area:agents), then for each entry:
gh api repos/OWNER/REPO/labels -f name=NAME -f color=COLOR -f description=DESC  # 422 = exists, fine

# Private repo on a free plan: GitHub offers neither branch protection nor rulesets.
# Check `gh api users/OWNER --jq .plan.name` (or the org plan); if it is "free" and the repo
# is private, skip this block and say so in the report. Everything else still applies.
# Branch protection on main: PR required, CI green, linear history, no force-push.
# Retrofit: first check `gh api repos/OWNER/REPO/rulesets`. If a ruleset already targets
# main, add the missing checks to that ruleset (GET it by id, add entries to its
# required_status_checks rule, PUT it back) and make sure the owner is in its bypass list
# (`bypass_actors`: {"actor_type": "RepositoryRole", "actor_id": 5, "bypass_mode": "always"});
# do not add classic protection on top. Otherwise use classic protection:
gh api -X PUT repos/OWNER/REPO/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["ci-pass", "conventional", "gitleaks"] },
  "enforce_admins": <false if the owner may bypass (question 14), true otherwise>,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

Some sandboxed environments refuse repository-settings writes (HTTP 403 "not permitted
through this proxy"). Then do not retry: give the user these commands as one block to run
in their own terminal, and say which ones are pending.

A check added by name before it ever ran is fine through the API, but the GitHub UI only
offers checks it has seen run once; tell the user if they will add one by hand. The
`conventional` check runs on `pull_request_target`, which GitHub does not trigger for PRs
opened by the Actions bot: release PRs need the owner's bypass (classic protection with
`enforce_admins: false`, or the ruleset bypass list).

Status check names are job names: `ci-pass` (the aggregator at the end of ci.yml, green only
when every CI job is), `conventional` (pr-title.yml) and `gitleaks` (secrets.yml). New CI jobs
only need adding to `ci-pass`'s `needs`, never to the protection. Reviews are not required:
the user merges their own PRs.

## 10. Roadmap

- Create the milestone **v0.1** (`gh api repos/OWNER/REPO/milestones -f title=v0.1`).
- One issue per v0.1 feature (Feature template fields: problem, proposal, acceptance criteria),
  attached to the milestone, labelled `type:feat` + one `priority:*` + its `area:*` labels.
  Add `good first issue` on the smallest one.
- Write `ROADMAP.md`: a short "Done" list and a numbered "Next" list where each step names its
  milestone and links its issues. Keep it in sync with the milestones.
- One Task issue for the README screenshot once the first UI exists, if relevant.
- One Task issue **"chore: first release"**, labelled `type:chore` + `priority:p2`, no
  milestone. Releases are off by default: the Release workflow only runs once the repository
  variable `RELEASES_ENABLED` is `true`. Its checklist: (1) the project does something useful
  end to end; (2) `gh variable set RELEASES_ENABLED --body true`; (3) merge the release PR
  release-please opens (v0.1.0, pinned by `release-as`); (4) remove `release-as` from
  `release-please-config.json` in a follow-up PR, or every later release stays 0.1.0.
  Never enable releases during kickoff.

## 11. Report

Finish with: the PR link (to review and merge), a note that releases are off until the
"first release" issue is done (and that release PRs then need the admin bypass, since
GitHub does not run all checks on PRs opened by the Actions bot), the issues created, the secrets to add in
**Settings → Secrets → Actions** if evals are used (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`),
and anything skipped or left for the user. Never merge the PR yourself.
