#!/usr/bin/env bash
# PreToolUse hook: stop the agent from reading or writing secret files.
# Blocks .env files (not .env.example / .sample / .template), private keys and
# credential files, whether the agent uses a file tool or a shell command.
# Exit 2 blocks the tool call and shows the reason to the agent.
#
# Extra protected folders or files (for example real data in private/): list them, one
# path relative to the project root per line, in .claude/protected-paths (blank lines and
# # comments are ignored), or colon-separated in KIT_PROTECTED_PATHS. Everything under a
# listed folder is blocked, for file tools and for shell commands that name it.
set -uo pipefail

[[ "${KIT_HOOKS_OFF:-}" == 1 ]] && exit 0

input="$(cat)"

field() { # <jq path>  — jq when available, python3 otherwise
  if command -v jq >/dev/null 2>&1; then
    jq -r "$1 // empty" <<<"$input"
  else
    python3 -c 'import json,sys
d=json.loads(sys.stdin.read())
for k in sys.argv[1].lstrip(".").split("."):
    d=d.get(k) if isinstance(d,dict) else None
print(d if isinstance(d,str) else "")' "$1" <<<"$input"
  fi
}

is_secret() { # <path or word>
  local base="${1##*/}"
  base="${base%\"}"; base="${base%\'}"; base="${base#\"}"; base="${base#\'}"
  case "$base" in
    .env.example|.env.sample|.env.template|.env.dist) return 1 ;;
    .env|.env.*|*.pem|*.key|*.p12|*.pfx|id_rsa|id_rsa.*|id_ed25519|id_ed25519.*|.netrc|.pgpass) return 0 ;;
  esac
  return 1
}

project="${CLAUDE_PROJECT_DIR:-$PWD}"
protected=()
if [[ -f "$project/.claude/protected-paths" ]]; then
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%#*}"; line="${line//[[:space:]]/}"
    [[ -n "$line" ]] && protected+=("$line")
  done <"$project/.claude/protected-paths"
fi
if [[ -n "${KIT_PROTECTED_PATHS:-}" ]]; then
  IFS=: read -r -a extra <<<"$KIT_PROTECTED_PATHS"
  protected+=("${extra[@]}")
fi

is_protected() { # <path or word>
  local w="$1" p
  (( ${#protected[@]} )) || return 1
  w="${w#\"}"; w="${w%\"}"; w="${w#\'}"; w="${w%\'}"
  w="${w#"$project"/}"
  while [[ "$w" == ./* ]]; do w="${w#./}"; done
  for p in "${protected[@]}"; do
    p="${p#./}"; p="${p%/}"
    [[ -n "$p" && ( "$w" == "$p" || "$w" == "$p"/* ) ]] && return 0
  done
  return 1
}

block_protected() {
  echo "Blocked by .claude/hooks/protect-secrets.sh: '$1' is in a protected path." >&2
  echo "Paths listed in .claude/protected-paths are off limits to agents. Ask the user." >&2
  exit 2
}

block() {
  echo "Blocked by .claude/hooks/protect-secrets.sh: '$1' looks like a secret file." >&2
  echo "Agents never read or write secrets. Ask the user to do it, or use .env.example." >&2
  exit 2
}

tool="$(field .tool_name)"
case "$tool" in
  Bash)
    cmd="$(field .tool_input.command)"
    # Split on whitespace, quotes, redirections and separators; check every word.
    set -f   # no glob expansion of the words
    for word in $(tr ' \t\n<>|;&()=' '\n' <<<"$cmd"); do
      is_secret "$word" && block "$word"
      is_protected "$word" && block_protected "$word"
    done
    ;;
  *)
    for key in .tool_input.file_path .tool_input.notebook_path .tool_input.path; do
      path="$(field "$key")"
      [[ -n "$path" ]] && is_secret "$path" && block "$path"
      [[ -n "$path" ]] && is_protected "$path" && block_protected "$path"
    done
    ;;
esac
exit 0
