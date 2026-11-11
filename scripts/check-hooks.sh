#!/usr/bin/env bash
# Exercise the template's Claude Code hooks against an instantiated Python project.
#   scripts/check-hooks.sh DIR     (DIR = output of apply-template.sh, after `uv sync`)
set -euo pipefail

dir="$(cd "${1:?usage: check-hooks.sh DIR}" && pwd)"
hooks="$dir/.claude/hooks"
fail=0

expect() { # <want exit> <hook> <json> <label>
  local got=0
  printf '%s' "$3" | CLAUDE_PROJECT_DIR="$dir" "$hooks/$2" >/dev/null 2>&1 || got=$?
  if [[ "$got" == "$1" ]]; then echo "ok   $4"; else echo "FAIL $4 (exit $got, want $1)"; fail=1; fi
}

read_json()  { printf '{"tool_name":"Read","tool_input":{"file_path":"%s"}}' "$1"; }
bash_json()  { printf '{"tool_name":"Bash","tool_input":{"command":"%s"}}' "$1"; }
edit_json()  { printf '{"tool_name":"Edit","tool_input":{"file_path":"%s"}}' "$1"; }

expect 2 protect-secrets.sh "$(read_json "$dir/.env")"             "blocks reading .env"
expect 2 protect-secrets.sh "$(read_json "$dir/.env.production")"  "blocks reading .env.production"
expect 0 protect-secrets.sh "$(read_json "$dir/.env.example")"     "allows .env.example"
expect 2 protect-secrets.sh "$(bash_json "cat .env | grep KEY")"   "blocks cat .env"
expect 2 protect-secrets.sh "$(bash_json "cp key.pem /tmp")"       "blocks a private key in a command"
expect 0 protect-secrets.sh "$(bash_json "uv run pytest -q")"      "allows ordinary commands"

printf '# real data\nprivate/\n' > "$dir/.claude/protected-paths"
expect 2 protect-secrets.sh "$(read_json "$dir/private/people.csv")"     "blocks a protected folder (file tool)"
expect 2 protect-secrets.sh "$(bash_json "cat ./private/people.csv")"    "blocks a protected folder (shell)"
expect 2 protect-secrets.sh "$(bash_json "head -n1 'private/x.csv'")"    "blocks a quoted protected path"
expect 0 protect-secrets.sh "$(bash_json "cat privately/notes.md")"      "allows a path that only shares the prefix"
rm "$dir/.claude/protected-paths"
expect 0 protect-secrets.sh "$(bash_json "cat private/people.csv")"      "no protected-paths file, nothing extra blocked"

expect 0 after-edit.sh "$(edit_json "$dir/src/app/llm.py")" "clean file passes"
cp "$dir/src/app/config.py" "$dir/config.bak"
printf '\nBROKEN = undefined_name\n' >> "$dir/src/app/config.py"
expect 2 after-edit.sh "$(edit_json "$dir/src/app/config.py")" "lint error is reported"
mv "$dir/config.bak" "$dir/src/app/config.py"

exit "$fail"
