#!/usr/bin/env bash
# Privacy guard: fail if any denylisted term (real people's names, a client's name, an
# address...) appears in tracked files or in the commit messages being checked.
#
#   DENYLIST="term one
#   term two" scripts/denylist-check.sh [<base-ref>]
#
# Terms come from the DENYLIST environment variable (one per line, or comma-separated), set
# from a GitHub secret in CI and never stored in the repo. Matching is case-insensitive and on
# whole words. Matches are reported by location only: the term itself is never printed.

set -euo pipefail

if [[ -z "${DENYLIST:-}" ]]; then
  echo "::error::DENYLIST is empty. Add the repository secret DENYLIST (Settings → Secrets → Actions)."
  exit 1
fi

patterns="$(mktemp)"
trap 'rm -f "$patterns"' EXIT
printf '%s\n' "$DENYLIST" | tr ',' '\n' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' | awk 'NF' > "$patterns"
count="$(wc -l < "$patterns" | tr -d ' ')"
echo "Checking $count denylisted terms."

found=0

if files="$(git grep -n -I -i -w -F -f "$patterns" -- . ':!scripts/denylist-check.sh' | cut -d: -f1,2)"; then
  echo "Denylisted term found in tracked files (file:line):"
  while IFS= read -r location; do echo "  $location"; done <<< "$files"
  found=1
fi

if [[ -n "${1:-}" ]]; then
  if hits="$(git log --format='%h %B%x00' "$1..HEAD" | tr '\0' '\n' | grep -i -w -F -f "$patterns" -c || true)" && [[ "$hits" != 0 ]]; then
    echo "Denylisted term found in $hits commit message line(s) since $1."
    found=1
  fi
fi

if (( found )); then
  echo "::error::Real data must never enter the repository (see DECISIONS.md). Remove it and rewrite the commits if needed."
  exit 1
fi
echo "No denylisted term found."
