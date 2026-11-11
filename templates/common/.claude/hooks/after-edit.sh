#!/usr/bin/env bash
# PostToolUse hook: after the agent edits a file, format and lint it, then run the
# tests related to it. Problems are sent back to the agent (exit 2) so it fixes them
# right away instead of finding out in CI. Missing tools are skipped silently.
set -uo pipefail

[[ "${KIT_HOOKS_OFF:-}" == 1 ]] && exit 0

input="$(cat)"
if command -v jq >/dev/null 2>&1; then
  file="$(jq -r '.tool_input.file_path // empty' <<<"$input")"
else
  file="$(python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("file_path") or "")' <<<"$input")"
fi
[[ -n "$file" && -f "$file" ]] || exit 0
file="$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"

# Nearest ancestor directory that contains <marker> (monorepos: apps/api, apps/web).
root_with() {
  local dir; dir="$(dirname "$file")"
  while [[ "$dir" != / ]]; do
    [[ -e "$dir/$1" ]] && { echo "$dir"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

# node_modules/.bin/<name> from the current directory or the nearest ancestor that has it
# (npm/pnpm workspaces hoist tools to the workspace root).
find_bin() {
  local dir="$PWD"
  while [[ "$dir" != / ]]; do
    [[ -x "$dir/node_modules/.bin/$1" ]] && { echo "$dir/node_modules/.bin/$1"; return 0; }
    dir="$(dirname "$dir")"
  done
  return 1
}

# Rust edition: first literal `edition = "NNNN"` found in a Cargo.toml walking up from the
# file (a member crate with `edition.workspace = true` falls through to the workspace root).
rust_edition() {
  local dir e; dir="$(dirname "$file")"
  while [[ "$dir" != / ]]; do
    if [[ -f "$dir/Cargo.toml" ]]; then
      e="$(sed -nE 's/^[[:space:]]*edition[[:space:]]*=[[:space:]]*"([0-9]{4})".*/\1/p' "$dir/Cargo.toml" | head -n1)"
      [[ -n "$e" ]] && { echo "$e"; return 0; }
    fi
    dir="$(dirname "$dir")"
  done
  echo 2024
}

report=""
run() { # <label> <command...>: record the output when the command fails
  local out
  if ! out="$("${@:2}" 2>&1)"; then
    report+="$1 failed:"$'\n'"$(tail -n 40 <<<"$out")"$'\n\n'
  fi
}

case "$file" in
  *.py)
    if root="$(root_with pyproject.toml)" && command -v uv >/dev/null 2>&1; then
      cd "$root" || exit 0
      run "ruff format" uv run --quiet ruff format "$file"
      run "ruff check" uv run --quiet ruff check --fix "$file"
      stem="$(basename "$file" .py)"
      if [[ "$stem" == test_* ]]; then
        tests=("$file")
      else
        mapfile -t tests < <(find tests -name "test_${stem}.py" 2>/dev/null)
      fi
      (( ${#tests[@]} )) && run "pytest" uv run --quiet pytest -q -x -o addopts="" "${tests[@]}"
    fi
    ;;
  *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs|*.json|*.css)
    if root="$(root_with package.json)"; then
      cd "$root" || exit 0
      if bin="$(find_bin biome)"; then
        run "biome" "$bin" check --write "$file"
      else
        # No Biome: ESLint (code files only) then Prettier, when the project has them.
        case "$file" in
          *.ts|*.tsx|*.js|*.jsx|*.mjs|*.cjs)
            bin="$(find_bin eslint)" && run "eslint" "$bin" --fix "$file" ;;
        esac
        bin="$(find_bin prettier)" && run "prettier" "$bin" --write "$file"
      fi
      if [[ "$file" == *.ts* && "$file" != */e2e/* ]] && bin="$(find_bin vitest)"; then
        run "vitest" "$bin" related --run --passWithNoTests "$file"
      fi
    fi
    ;;
  *.rs)
    if root="$(root_with Cargo.toml)" && command -v cargo >/dev/null 2>&1; then
      cd "$root" || exit 0
      run "rustfmt" rustfmt --edition "$(rust_edition)" "$file"
      run "clippy" cargo clippy --quiet --all-targets -- -D warnings
    fi
    ;;
esac

if [[ -n "$report" ]]; then
  shown="$file"
  [[ -n "${CLAUDE_PROJECT_DIR:-}" ]] && shown="${file#"$CLAUDE_PROJECT_DIR"/}"
  printf 'Checks after editing %s:\n\n%s' "$shown" "$report" >&2
  exit 2
fi
exit 0
