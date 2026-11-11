#!/usr/bin/env bash
# Copy kit templates into a project directory.
#
#   apply-template.sh --target DIR --stack common|python|typescript [--stack ...]
#                     [--subdir SUB] [--var KEY=VALUE ...] [--no-clobber]
#
# Rules
#   - Stacks are applied in the order given; later files overwrite earlier ones.
#   - `<name>.append` files are appended to `<name>` instead of replacing it.
#   - `_kit.md` files are notes for the skill and are never copied.
#   - Only {{KEY}} placeholders passed with --var are replaced; anything else in
#     double braces (promptfoo {{question}}, GitHub ${{ }}) is left alone.
#   - --no-clobber (retrofit mode) never touches an existing file; conflicts are
#     listed at the end so the agent can merge them by hand.
#   - --subdir puts a stack's files under SUB/ (monorepo: apps/api, apps/web).
#     It applies to the --stack flags that follow it; `.github/` and `.devcontainer/`
#     always go to the root.

set -euo pipefail

KIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET=""
NO_CLOBBER=0
SUBDIR=""
declare -a PLAN=()   # entries: "stack|subdir"
declare -a VARS=()
declare -a CONFLICTS=()
declare -a WRITTEN=()

while (( $# )); do
  case "$1" in
    --target)     TARGET="$2"; shift 2 ;;
    --stack)      PLAN+=("$2|$SUBDIR"); shift 2 ;;
    --subdir)     SUBDIR="$2"; shift 2 ;;
    --var)        VARS+=("$2"); shift 2 ;;
    --no-clobber) NO_CLOBBER=1; shift ;;
    -h|--help)    sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *)            echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

[[ -n "$TARGET" ]] || { echo "--target is required" >&2; exit 2; }
(( ${#PLAN[@]} )) || { echo "at least one --stack is required" >&2; exit 2; }
mkdir -p "$TARGET"

substitute() { # <file>
  local file="$1" kv key value
  for kv in "${VARS[@]+"${VARS[@]}"}"; do
    key="${kv%%=*}"; value="${kv#*=}"
    # Escape characters special to sed's replacement side.
    value="$(printf '%s' "$value" | sed 's/[&|\\]/\\&/g')"
    sed -i "s|{{${key}}}|${value}|g" "$file"
  done
}

for entry in "${PLAN[@]}"; do
  stack="${entry%%|*}"; sub="${entry#*|}"
  src="$KIT_ROOT/templates/$stack"
  [[ -d "$src" ]] || { echo "Unknown stack: $stack" >&2; exit 2; }

  while IFS= read -r -d '' file; do
    rel="${file#"$src"/}"
    [[ "$(basename "$rel")" == "_kit.md" ]] && continue

    dest_rel="$rel"
    clobber_ok=$(( ! NO_CLOBBER ))
    if [[ -n "$sub" ]]; then
      if [[ "$rel" == .github/workflows/* ]]; then
        # ci.yml -> ci-api.yml so two stacks' workflows can live side by side.
        name="$(basename "$rel" .yml)"
        dest_rel=".github/workflows/${name}-$(basename "$sub").yml"
      elif [[ "$rel" == .github/* || "$rel" == .devcontainer/* ]]; then
        # Shared repo-level file (dependabot.yml, devcontainer.json): stays at the root,
        # never overwritten; the first stack wins and the rest is listed to merge by hand.
        clobber_ok=0
      else
        dest_rel="$sub/$rel"
      fi
    fi

    if [[ "$dest_rel" == *.append ]]; then
      dest="$TARGET/${dest_rel%.append}"
      mkdir -p "$(dirname "$dest")"
      tmp="$(mktemp)"; cp "$file" "$tmp"; substitute "$tmp"
      if [[ -f "$dest" ]] && grep -qF -- "$(head -n 2 "$tmp" | tail -n 1)" "$dest"; then
        rm "$tmp"; continue   # already appended
      fi
      cat "$tmp" >> "$dest"; rm "$tmp"
      WRITTEN+=("${dest_rel%.append} (appended)")
      continue
    fi

    dest="$TARGET/$dest_rel"
    if [[ -e "$dest" ]] && (( ! clobber_ok )); then
      CONFLICTS+=("$dest_rel")
      continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp "$file" "$dest"
    substitute "$dest"
    WRITTEN+=("$dest_rel")
  done < <(find "$src" -type f -print0 | sort -z)
done

printf 'Written (%d):\n' "${#WRITTEN[@]}"
printf '  %s\n' "${WRITTEN[@]+"${WRITTEN[@]}"}"
if (( ${#CONFLICTS[@]} )); then
  printf 'Skipped, already exist — merge by hand (%d):\n' "${#CONFLICTS[@]}"
  printf '  %s\n' "${CONFLICTS[@]}"
fi
left="$(grep -rlE '\{\{[A-Z][A-Z_]+\}\}' "$TARGET" --exclude-dir=node_modules --exclude-dir=.git 2>/dev/null || true)"
if [[ -n "$left" ]]; then
  echo "Unfilled {{PLACEHOLDERS}} remain in:"
  printf '%s\n' "$left" | sed "s|^$TARGET/|  |"
fi
