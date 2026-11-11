#!/usr/bin/env bash
# `cond && row PASS ... || row FAIL ...` is safe in this file: row() always returns 0.
# shellcheck disable=SC2015
# Read-only audit of a repository against the kit conventions.
#
#   scripts/audit.sh OWNER/REPO [LOCAL_CLONE]
#
# Prints a Markdown table (PASS / WARN / FAIL), then the commands that fix what the agent
# cannot change itself (repository settings need the owner). Without LOCAL_CLONE, the
# file checks read the default branch through the API. Exit code 1 when anything FAILs.
# Needs: gh (authenticated), jq, git.
set -uo pipefail

repo="${1:?usage: audit.sh OWNER/REPO [LOCAL_CLONE]}"
clone="${2:-}"
rows=()
fixes=()
failed=0

row() { # <PASS|WARN|FAIL> <check> <detail>
  rows+=("| $1 | $2 | $3 |")
  [[ "$1" == FAIL ]] && failed=1
  return 0
}
api() { gh api "$@" 2>/dev/null; }

meta="$(api "repos/$repo")" || { echo "Cannot read $repo (missing or no access)." >&2; exit 2; }
branch="$(jq -r .default_branch <<<"$meta")"

# --- Repository settings -------------------------------------------------------------------
[[ "$branch" == main ]] && row PASS "Default branch" main ||
  { row FAIL "Default branch" "\`$branch\`, expected \`main\`"; fixes+=("gh api -X POST repos/$repo/branches/$branch/rename -f new_name=main"); }

merge="$(jq -r '[.allow_squash_merge, .allow_merge_commit, .allow_rebase_merge, .delete_branch_on_merge] | map(tostring) | join(" ")' <<<"$meta")"
if [[ "$merge" == "true false false true" ]]; then
  row PASS "Merge settings" "squash only, branches deleted on merge"
else
  row FAIL "Merge settings" "squash/merge/rebase/delete-branch = $merge"
  fixes+=("gh api -X PATCH repos/$repo -F allow_squash_merge=true -F allow_merge_commit=false -F allow_rebase_merge=false -F delete_branch_on_merge=true -f squash_merge_commit_title=PR_TITLE -f squash_merge_commit_message=PR_BODY")
fi

[[ -n "$(jq -r '.description // ""' <<<"$meta")" ]] && row PASS "About description" set || row FAIL "About description" missing
topics="$(jq -r '.topics | length' <<<"$meta")"
(( topics > 0 )) && row PASS "Topics" "$topics" ||
  { row FAIL "Topics" none; fixes+=("gh api -X PUT repos/$repo/topics -f \"names[]=<topic>\" -f \"names[]=<topic>\""); }

# --- Branch protection (classic protection or rulesets) ----------------------------------
required="$(api "repos/$repo/branches/$branch/protection" --jq '.required_status_checks.contexts[]' || true)"
for id in $(api "repos/$repo/rulesets" --jq '.[] | select(.enforcement == "active") | .id' || true); do
  required+=$'\n'"$(api "repos/$repo/rulesets/$id" --jq '.rules[] | select(.type == "required_status_checks") | .parameters.required_status_checks[].context' || true)"
done
missing=()
for check in ci-pass conventional gitleaks; do grep -qx "$check" <<<"$required" || missing+=("$check"); done
if (( ${#missing[@]} == 0 )); then
  row PASS "Protection of \`$branch\`" "requires ci-pass, conventional, gitleaks"
else
  row FAIL "Protection of \`$branch\`" "missing required check(s): ${missing[*]} (or protection not readable without admin)"
  fixes+=("B='{\"required_status_checks\":{\"strict\":true,\"contexts\":[\"ci-pass\",\"conventional\",\"gitleaks\"]},\"enforce_admins\":false,\"required_pull_request_reviews\":null,\"restrictions\":null,\"required_linear_history\":true,\"allow_force_pushes\":false,\"allow_deletions\":false}'; echo \"\$B\" | gh api -X PUT repos/$repo/branches/$branch/protection --input -")
fi

# --- Labels and issues ------------------------------------------------------------------
labels="$(api "repos/$repo/labels?per_page=100" --paginate --jq '.[].name')"
for prefix in type: priority: area:; do
  n="$(grep -c "^$prefix" <<<"$labels" || true)"
  (( n > 0 )) && row PASS "Labels \`$prefix*\`" "$n" || row FAIL "Labels \`$prefix*\`" "none (add them to .github/labels.yml)"
done
unlabeled="$(api "repos/$repo/issues?state=open&per_page=100" --paginate --jq '.[] | select(.pull_request | not)
  | select(([.labels[].name] | any(startswith("type:"))) and ([.labels[].name] | any(startswith("priority:"))) | not)
  | "#\(.number)"' | paste -sd' ' -)"
[[ -z "$unlabeled" ]] && row PASS "Open issues labelled" "all have type:* and priority:*" ||
  row FAIL "Open issues labelled" "missing type:* or priority:*: $unlabeled"

# --- Files ------------------------------------------------------------------------------
has_file() {
  if [[ -n "$clone" ]]; then [[ -e "$clone/$1" ]]; else api "repos/$repo/contents/$1?ref=$branch" >/dev/null; fi
}
absent=()
for f in README.md LICENSE AGENTS.md CLAUDE.md CONTRIBUTING.md .github/workflows/ci.yml \
  .github/workflows/pr-title.yml .github/workflows/secrets.yml .github/dependabot.yml \
  .github/labels.yml .claude/settings.json; do
  has_file "$f" || absent+=("$f")
done
(( ${#absent[@]} == 0 )) && row PASS "Kit files" present || row FAIL "Kit files" "missing: ${absent[*]}"
if has_file .pre-commit-config.yaml || has_file .husky || has_file commitlint.config.js || has_file commitlint.config.mjs; then
  row PASS "Commit-msg hook" "configured"
else
  row WARN "Commit-msg hook" "no pre-commit or commitlint config"
fi

sha="$(api "repos/$repo/commits/$branch" --jq .sha)"
if [[ -n "$clone" && "$(git -C "$clone" rev-parse HEAD 2>/dev/null)" != "$sha" ]]; then
  row WARN "Local clone" "not at origin/$branch: file checks below may be stale (git pull first)"
fi
if [[ -n "$clone" ]]; then
  unpinned="$(git -C "$clone" grep -nE '^\s*-?\s*uses:\s*[^./]' -- .github | grep -vE '@[0-9a-f]{40}' | cut -d: -f1,2 | paste -sd' ' -)"
  [[ -z "$unpinned" ]] && row PASS "Actions pinned by SHA" all || row FAIL "Actions pinned by SHA" "$unpinned"

  if [[ -f "$clone/ROADMAP.md" ]]; then
    stale=()
    while IFS= read -r line; do
      for n in $(grep -oE '#[0-9]+' <<<"$line" | tr -d '#'); do
        state="$(api "repos/$repo/issues/$n" --jq .state || true)"
        if [[ "$line" == *"[ ]"* && "$state" == closed ]]; then stale+=("#$n done but unchecked"); fi
        if [[ "$line" == *"[x]"* && "$state" == open ]]; then stale+=("#$n checked but open"); fi
      done
    done < <(awk '/^[[:space:]]*[-*] \[( |x)\]/ { if (item) print item; item = $0; next }
                  /^[[:space:]]+[^[:space:]-*]/ && item { item = item " " $0; next }
                  { if (item) print item; item = "" }
                  END { if (item) print item }' "$clone/ROADMAP.md")
    (( ${#stale[@]} == 0 )) && row PASS "ROADMAP matches issues" ok || row FAIL "ROADMAP matches issues" "${stale[*]}"
  else
    row WARN "ROADMAP matches issues" "no ROADMAP.md"
  fi

  french="$(LC_ALL=C.UTF-8 git -C "$clone" grep -lIP '[àâçéèêëîïôùûœ]' -- . ':!*.lock' ':!*lock.json' ':!*lock.yaml' ':!*.svg' 2>/dev/null | head -5 | paste -sd' ' -)"
  [[ -z "$french" ]] && row PASS "English only" "no accented text" ||
    row WARN "English only" "accented text in: $french (fine if intended, e.g. a UI glossary)"
else
  row WARN "Local checks" "pass a local clone to check pinning, ROADMAP and language"
fi

# --- CI and Dependabot ------------------------------------------------------------------
runs="$(api "repos/$repo/commits/$sha/check-runs?per_page=100" --jq '.check_runs[] | select(.conclusion == "failure" or .conclusion == "timed_out") | .name' | sort -u)"
bad="$(grep -vx Dependabot <<<"$runs" | paste -sd, - | sed 's/,/, /g')"
[[ -z "$bad" ]] && row PASS "CI on \`$branch\`" green || row FAIL "CI on \`$branch\`" "failing: $bad"
grep -qx Dependabot <<<"$runs" && row WARN "Dependabot update job" "failed on the last commit (Insights → Dependency graph → Dependabot)"

red=()
for n in $(api "repos/$repo/pulls?state=open&per_page=100" --jq '.[] | select(.user.login == "dependabot[bot]") | .number'); do
  head="$(api "repos/$repo/pulls/$n" --jq .head.sha)"
  failing="$(api "repos/$repo/commits/$head/check-runs" --jq '[.check_runs[] | select(.conclusion == "failure")] | length')"
  [[ "${failing:-0}" != 0 ]] && red+=("#$n")
done
(( ${#red[@]} == 0 )) && row PASS "Dependabot PRs" "none failing" || row WARN "Dependabot PRs" "failing CI: ${red[*]} (do not merge; fix or ignore the update)"

# --- Report -----------------------------------------------------------------------------
echo "## Audit of $repo"
echo
echo "| Result | Check | Detail |"
echo "|---|---|---|"
printf '%s\n' "${rows[@]}"
if (( ${#fixes[@]} )); then
  echo
  echo "### Commands for the owner (repository settings)"
  echo
  echo '```bash'
  printf '%s\n' "${fixes[@]}"
  echo '```'
fi
exit "$failed"
