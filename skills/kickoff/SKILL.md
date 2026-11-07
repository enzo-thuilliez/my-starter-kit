---
name: kickoff
description: Bootstrap a GitHub repository the kit way — interview, structure, AGENTS.md, selling README, CI, issue/PR flow, branch protection, first issues and code-intel indexing. Use when the user runs /kit:kickoff, starts a new project or repo, or wants to retrofit an existing repo with the kit's conventions.
---

# Kickoff

Turn an idea (or an existing repo) into a repository that is ready for agent-driven work:
structured, documented, tested, with an issue → branch → PR flow enforced on GitHub.

Everything written into the repo is in **English**. Talk to the user in the language they use.

## Where things are

The kit root is two directories above this `SKILL.md` (`<kit>/skills/kickoff/SKILL.md`).

- `<kit>/scripts/apply-template.sh` copies templates. Run it with `--help` once to see the rules.
- `<kit>/templates/common/` goes into every repo.
- `<kit>/templates/python/` and `<kit>/templates/typescript/` are the stacks. Read the stack's
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

## 2. Interview (10–15 questions)

Ask with the question tool, four questions per round, options first and free text always possible.
Skip any question the repo or the conversation already answers. Cover:

1. **Name** (kebab-case repo name) and **one-line pitch** (this becomes the GitHub About).
2. **Target user** and the problem they have today.
3. **Core features for v0.1** (3–7). These become the first issues.
4. **Out of scope** for v0.1.
5. **Stack**: Python (FastAPI) / TypeScript (Next.js) / both as a monorepo (`apps/api` + `apps/web`).
6. **LLM usage**: none / single model / multi-provider; which providers (Anthropic, OpenAI).
7. **Data**: database or storage needed? (Postgres, SQLite, Supabase, files, none)
8. **Auth**: none / simple / provider (Clerk, Supabase Auth, NextAuth).
9. **Deployment target**: Vercel, Docker/VPS, Fly, Railway, none yet.
10. **Evals**: what does a correct answer look like? Two or three example cases.
11. **Visuals for the README**: screenshot or GIF later, logo or not.
12. **Topics** for GitHub (suggest 5–8, let the user edit).
13. Anything an agent would likely get wrong in this project (conventions, domain rules).

Then write a **short spec** (pitch, user, v0.1 features, stack, LLM, data, auth, deploy, evals)
and ask the user to confirm or edit it. Do not create anything before the spec is confirmed.

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

- **new**: `gh repo create <owner>/<name> --public --description "<pitch>"`, then clone it or
  `git init && git remote add origin ...` in the current folder.
- **new** and **empty**: commit a minimal `README.md` (title + pitch) and the license on `main`
  (`chore: initial commit`) and push. This is the only direct commit to `main`.
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
$KIT/scripts/apply-template.sh --target . --stack common --stack <python|typescript> "${VARS[@]}"
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
  path filters). Merge `.github/dependabot.yml` by hand (one entry per ecosystem and directory),
  and move `release-please-config.json` / `.release-please-manifest.json` to the root with one
  package per app.
- **Retrofit**: for every file the script reports as skipped, merge what is missing into the
  existing file by hand. Never rewrite the project's own code or config wholesale.
- Remove the options the interview ruled out (no LLM → see "Options to drop" in `_kit.md`).
- Add what the interview asked for that templates don't cover (database client, auth) only
  as dependencies + one minimal wiring file with a test; the features themselves are issues.

## 7. Write the docs

**AGENTS.md** — fill every `<!-- kickoff ... -->` marker: project summary, stack, the command
table from `_kit.md`, folder map, conventions (including the user's answer to question 13).
Leave no marker and no `{{PLACEHOLDER}}` behind.

**README.md** — selling, in this order:

1. Title, one-line pitch, badges (CI, license, release).
2. Screenshot/GIF placeholder line (`<!-- screenshot: add after first UI -->`) if visual.
3. **Why** — the problem, two or three sentences.
4. **Features** — the v0.1 features, marked planned until built.
5. **Quick start** — clone, `.env` from `.env.example`, install, run. Commands must work.
6. **How it works** — a short mermaid diagram of the main moving parts.
7. **Development** — link to `AGENTS.md` and `CONTRIBUTING.md`, test/lint commands.
8. **License**.

## 8. Verify, index, open the PR

1. Run the stack's lint, type-check and tests. Everything must pass. Fix, don't skip.
2. `pre-commit install && pre-commit run --all-files` (commit any auto-fixes).
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

# Squash only, PR title as commit title, delete merged branches
gh api -X PATCH repos/OWNER/REPO \
  -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false \
  -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE \
  -f squash_merge_commit_message=PR_BODY

# Labels now (the label-sync workflow only runs once merged on main)
#   for each entry of .github/labels.yml:
gh api repos/OWNER/REPO/labels -f name=NAME -f color=COLOR -f description=DESC  # 422 = exists, fine

# Branch protection on main: PR required, CI green, linear history, no force-push
gh api -X PUT repos/OWNER/REPO/branches/main/protection --input - <<'JSON'
{
  "required_status_checks": { "strict": true, "contexts": ["check", "conventional", "gitleaks"] },
  "enforce_admins": false,
  "required_pull_request_reviews": null,
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
JSON
```

Status check names are the **job ids** of the workflows (`check` from ci.yml, `conventional`
from pr-title.yml, `gitleaks` from secrets.yml). In a monorepo, `check` appears once per
workflow; list it once. Reviews are not required: the user merges their own PRs.

## 10. Roadmap

- Create the milestone **v0.1** (`gh api repos/OWNER/REPO/milestones -f title=v0.1`).
- One issue per v0.1 feature (Feature template fields: problem, proposal, acceptance criteria),
  attached to the milestone, labelled `enhancement`. Add a `good first issue` on the smallest one.
- One Task issue for the README screenshot once the first UI exists, if relevant.

## 11. Report

Finish with: the PR link (to review and merge), the issues created, the secrets to add in
**Settings → Secrets → Actions** if evals are used (`ANTHROPIC_API_KEY`, `OPENAI_API_KEY`),
and anything skipped or left for the user. Never merge the PR yourself.
