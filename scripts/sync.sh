#!/usr/bin/env bash
# Compare an existing repo with what the current templates would generate, file by file.
#
#   scripts/sync.sh [--diff] --target DIR --stack common [--subdir apps/api] --stack python ... --var K=V ...
#
# Takes the same arguments as apply-template.sh. Renders the templates into a temporary folder,
# then reports, for every kit-managed file (CI, hooks, settings, tooling config): missing,
# identical, or different (with line counts; the full diff with --diff). Project files
# (README, AGENTS.md, source, tests, manifests) are listed as not compared: they belong to the
# project. Read-only: it never writes into DIR.
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
show_diff=0
target=""
args=()
while (($#)); do
  case "$1" in
    --diff) show_diff=1 ;;
    --target) target="$2"; shift ;;
    *) args+=("$1") ;;
  esac
  shift
done
[[ -n "$target" && -d "$target" ]] || { echo "usage: sync.sh [--diff] --target DIR <apply-template args>" >&2; exit 2; }
target="$(cd "$target" && pwd)"

rendered="$(mktemp -d)"
trap 'rm -rf "$rendered"' EXIT
"$here/apply-template.sh" --target "$rendered" "${args[@]}" >/dev/null

# Files the kit owns. Everything else is the project's once kickoff is done.
managed() {
  case "$1" in
    .github/* | .claude/* | .devcontainer/* | .pre-commit-config.yaml | .editorconfig | \
      */.github/* | deny.toml | clippy.toml | rustfmt.toml | rust-toolchain.toml | \
      */deny.toml | */clippy.toml | */rustfmt.toml | */rust-toolchain.toml | \
      scripts/denylist-check.sh | release-please-config.json | */release-please-config.json) return 0 ;;
  esac
  return 1
}

rows=()
skipped=()
while IFS= read -r rel; do
  rel="${rel#./}"
  if [[ "$(basename "$rel")" == .gitignore ]]; then
    # Appended file: check that every kit line is present.
    if [[ -f "$target/$rel" ]]; then
      lacking="$(grep -vE '^\s*(#|$)' "$rendered/$rel" | grep -vxFf "$target/$rel" | paste -sd' ' - || true)"
      if [[ -z "$lacking" ]]; then rows+=("| identical | \`$rel\` | every kit entry present |")
      else rows+=("| differs | \`$rel\` | missing entries: $lacking |"); fi
    else
      rows+=("| missing | \`$rel\` | |")
    fi
    continue
  fi
  if ! managed "$rel"; then
    skipped+=("$rel")
    continue
  fi
  if [[ ! -e "$target/$rel" ]]; then
    rows+=("| missing | \`$rel\` | new in the kit |")
  elif cmp -s "$rendered/$rel" "$target/$rel"; then
    rows+=("| identical | \`$rel\` | |")
  else
    stat="$(diff "$target/$rel" "$rendered/$rel" | grep -cE '^>' || true) kit line(s) not in the repo, $(diff "$target/$rel" "$rendered/$rel" | grep -cE '^<' || true) repo line(s) not in the kit"
    rows+=("| differs | \`$rel\` | $stat |")
    if ((show_diff)); then
      diffs+=$'\n'"#### \`$rel\`"$'\n\n```diff\n'"$(diff -u --label "repo/$rel" --label "kit/$rel" "$target/$rel" "$rendered/$rel" || true)"$'\n```\n'
    fi
  fi
done < <(cd "$rendered" && find . -type f | sort)

echo "## Template sync: $(basename "$target")"
echo
echo "| Status | File | Detail |"
echo "|---|---|---|"
printf '%s\n' "${rows[@]}" | sort -t'|' -k2,2 -s
echo
echo "Not compared (project-owned): ${#skipped[@]} file(s), e.g. $(printf '%s\n' "${skipped[@]}" | head -5 | paste -sd' ' -)."
if ((show_diff)) && [[ -n "${diffs:-}" ]]; then
  echo
  echo "### Diffs (repo → kit)"
  echo "${diffs}"
fi
