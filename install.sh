#!/usr/bin/env bash
# my-starter-kit — machine setup for Claude Code.
# Idempotent: safe to run again at any time; already-installed pieces are skipped.
#
#   ./install.sh [--workflow=agent-skills|ecc] [--with-omniroute] [--with-langfuse]
#                [--windows-too] [--dry-run] [--help]

set -euo pipefail

REPO="enzo-thuilliez/my-starter-kit"
RAW="https://raw.githubusercontent.com/${REPO}/main"
WORKFLOW="agent-skills"
WITH_OMNIROUTE=0
WITH_LANGFUSE=0
WINDOWS_TOO=0
DRY_RUN=0

# Packages whose npm install scripts must run (native builds). @scarf/scarf is
# telemetry and is deliberately left out.
NPM_ALLOW_SCRIPTS=(
  gitnexus @ladybugdb/core onnxruntime-node protobufjs esbuild
  tree-sitter tree-sitter-c-sharp tree-sitter-cpp tree-sitter-go tree-sitter-java
  tree-sitter-javascript tree-sitter-php tree-sitter-python tree-sitter-ruby
  tree-sitter-rust tree-sitter-typescript
  omniroute keytar @parcel/watcher @swc/core
)

BEGIN_MARK="<!-- my-starter-kit:begin -->"
END_MARK="<!-- my-starter-kit:end -->"

# ---------------------------------------------------------------- helpers

bold() { printf '\033[1m%s\033[0m\n' "$*"; }
info() { printf '  \033[36m•\033[0m %s\n' "$*"; }
ok()   { printf '  \033[32m✔\033[0m %s\n' "$*"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$*" >&2; }
die()  { printf '  \033[31m✘\033[0m %s\n' "$*" >&2; exit 1; }
has()  { command -v "$1" >/dev/null 2>&1; }

run() {
  if (( DRY_RUN )); then
    printf '  \033[2m$ %s\033[0m\n' "$*"
  else
    "$@"
  fi
}

usage() {
  sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'
  cat <<'EOF'

Options:
  --workflow=NAME     Agent workflow layer: agent-skills (default) or ecc.
                      The other one is uninstalled to avoid overlapping hooks.
  --with-omniroute    Install the OmniRoute LLM gateway (needs Node 22 or 24).
  --with-langfuse     Run a self-hosted Langfuse with docker compose.
  --windows-too       Print the PowerShell steps for the Windows-side Claude Code.
  --dry-run           Print what would run, change nothing.
  -h, --help          Show this help.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --workflow=*)     WORKFLOW="${arg#*=}" ;;
    --with-omniroute) WITH_OMNIROUTE=1 ;;
    --with-langfuse)  WITH_LANGFUSE=1 ;;
    --windows-too)    WINDOWS_TOO=1 ;;
    --dry-run)        DRY_RUN=1 ;;
    -h|--help)        usage; exit 0 ;;
    *)                die "Unknown option: $arg (see --help)" ;;
  esac
done
[[ "$WORKFLOW" == "agent-skills" || "$WORKFLOW" == "ecc" ]] \
  || die "--workflow must be agent-skills or ecc"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" 2>/dev/null && pwd || echo "")"

# ---------------------------------------------------------------- 1. system

step_system() {
  bold "1/7 System dependencies"
  local missing=()
  for pkg in build-essential libsecret-1-dev git curl jq; do
    dpkg -s "$pkg" >/dev/null 2>&1 || missing+=("$pkg")
  done
  if (( ${#missing[@]} )); then
    if has apt-get; then
      info "Installing with apt: ${missing[*]}"
      run sudo apt-get update -qq
      run sudo apt-get install -y -qq "${missing[@]}"
    else
      warn "Not a Debian/Ubuntu system. Install manually: ${missing[*]}"
    fi
  else
    ok "apt packages present"
  fi

  has node || die "Node.js is required (22 or 24 recommended). Install it with nvm or fnm, then re-run."
  local node_major; node_major="$(node -p 'process.versions.node.split(".")[0]')"
  (( node_major >= 18 )) || die "Node $node_major is too old; need 18+ (22 or 24 for OmniRoute)."
  ok "node $(node --version)"

  if ! has uv; then
    info "Installing uv"
    run sh -c 'curl -LsSf https://astral.sh/uv/install.sh | sh'
    export PATH="$HOME/.local/bin:$PATH"
  fi
  ok "uv $(uv --version 2>/dev/null | awk '{print $2}')"

  has claude || die "Claude Code CLI not found. Install it first: https://code.claude.com/docs"
  ok "claude $(claude --version 2>/dev/null | awk '{print $1}')"

  has gh || warn "GitHub CLI (gh) not found — /kit:kickoff needs it. Install: https://cli.github.com"

  # Allow native install scripts once, user-wide, merged with any existing list.
  local current merged
  current="$(npm config get allow-scripts --location=user 2>/dev/null || true)"
  [[ "$current" == "undefined" || "$current" == "null" ]] && current=""
  merged="$(printf '%s\n' "${current//,/$'\n'}" "${NPM_ALLOW_SCRIPTS[@]}" | awk 'NF && !seen[$0]++' | paste -sd, -)"
  if [[ "$merged" != "$current" ]]; then
    run npm config set "allow-scripts=$merged" --location=user
    ok "npm allow-scripts updated"
  else
    ok "npm allow-scripts already set"
  fi
}

# ---------------------------------------------------------------- 2. plugins

plugin_installed()      { claude plugin list 2>/dev/null | grep -q "$1"; }
marketplace_present()   { claude plugin marketplace list 2>/dev/null | grep -q "$1"; }

ensure_plugin() { # <marketplace-source> <marketplace-name> <plugin@marketplace>
  marketplace_present "$2" || run claude plugin marketplace add "$1"
  if plugin_installed "$3"; then
    run claude plugin update "$3" >/dev/null 2>&1 || true
    ok "$3"
  else
    run claude plugin install "$3"
  fi
}

remove_plugin() { # <plugin@marketplace>
  if plugin_installed "$1"; then
    info "Uninstalling $1 (overlaps with --workflow=$WORKFLOW)"
    run claude plugin uninstall "$1"
  fi
}

ensure_line() { # <file> <line>
  [[ -f "$1" ]] || return 0
  grep -qxF "$2" "$1" || run sh -c "printf '%s\n' '$2' >> '$1'"
}

step_plugins() {
  bold "2/7 Claude Code plugins"
  ensure_plugin "$REPO"                     my-starter-kit    kit@my-starter-kit
  ensure_plugin DietrichGebert/ponytail     ponytail          ponytail@ponytail
  ensure_plugin haydenschmitty/floorplan    floorplan         floorplan@floorplan

  if [[ "$WORKFLOW" == "agent-skills" ]]; then
    ensure_plugin addyosmani/agent-skills   addy-agent-skills agent-skills@addy-agent-skills
    remove_plugin ecc@ecc
  else
    ensure_plugin https://github.com/affaan-m/ECC ecc ecc@ecc
    remove_plugin agent-skills@addy-agent-skills
    for rc in "$HOME/.bashrc" "$HOME/.zshrc"; do
      ensure_line "$rc" 'export ECC_HOOK_PROFILE=minimal'
    done
    ok "ECC_HOOK_PROFILE=minimal set in your shell rc"
  fi
}

# ---------------------------------------------------------------- 3. code intel

step_code_intel() {
  bold "3/7 Code intelligence (GitNexus + Graphify)"
  if has gitnexus; then
    ok "gitnexus $(gitnexus --version 2>/dev/null | head -1)"
  else
    run npm install -g gitnexus
  fi
  run gitnexus setup >/dev/null
  ok "gitnexus MCP, skills and hooks configured"

  if has graphify; then
    run uv tool upgrade graphifyy >/dev/null 2>&1 || true
    ok "graphify"
  else
    run uv tool install graphifyy
  fi
  run graphify install >/dev/null
  ok "graphify skill installed"
}

# ---------------------------------------------------------------- 4. MCP servers

ensure_mcp() { # <name> <command...>
  local name="$1"; shift
  if claude mcp get "$name" >/dev/null 2>&1; then
    ok "MCP $name"
  else
    run claude mcp add --scope user "$name" -- "$@"
  fi
}

step_mcp() {
  bold "4/7 MCP servers"
  ensure_mcp context7   npx -y @upstash/context7-mcp
  ensure_mcp playwright npx -y @playwright/mcp@latest
}

# ---------------------------------------------------------------- 5. CLIs

step_clis() {
  bold "5/7 CLIs"
  for pkg in ccusage promptfoo; do
    if has "$pkg"; then ok "$pkg"; else run npm install -g "$pkg"; fi
  done
  if has pre-commit; then ok "pre-commit"; else run uv tool install pre-commit; fi
}

# ---------------------------------------------------------------- 6. global rules

step_global_rules() {
  bold "6/7 Global rules (~/.claude/CLAUDE.md)"
  local src target="$HOME/.claude/CLAUDE.md" tmp
  tmp="$(mktemp)"
  if [[ -n "$SCRIPT_DIR" && -f "$SCRIPT_DIR/global/CLAUDE.md" ]]; then
    src="$SCRIPT_DIR/global/CLAUDE.md"
  else
    src="$tmp.src"
    curl -fsSL "$RAW/global/CLAUDE.md" -o "$src" || { warn "Could not download global/CLAUDE.md"; return 0; }
  fi

  mkdir -p "$(dirname "$target")"
  touch "$target"
  # Replace our block if present, otherwise append it. Other tools' content
  # (Graphify, GitNexus, your own notes) is left untouched.
  awk -v b="$BEGIN_MARK" -v e="$END_MARK" -v src="$src" '
    function block() { print b; while ((getline l < src) > 0) print l; print e }
    $0 == b { skip = 1; block(); done = 1; next }
    $0 == e { skip = 0; next }
    !skip   { print }
    END     { if (!done) { print ""; block() } }
  ' "$target" > "$tmp"

  if cmp -s "$tmp" "$target"; then
    ok "already up to date"
  elif (( DRY_RUN )); then
    info "would update $target"
  else
    cp "$target" "$target.bak"
    mv "$tmp" "$target"
    ok "updated (backup: $target.bak)"
  fi
  rm -f "$tmp" "$tmp.src"
}

# ---------------------------------------------------------------- 7. extras

step_extras() {
  bold "7/7 Extras"
  if (( WITH_OMNIROUTE )); then
    local node_major; node_major="$(node -p 'process.versions.node.split(".")[0]')"
    if [[ "$node_major" != 22 && "$node_major" != 24 ]]; then
      warn "OmniRoute needs Node 22 or 24 (you have $node_major) — skipped"
    elif has omniroute; then
      ok "omniroute"
    else
      run npm install -g omniroute
      info "Start it with: omniroute  → dashboard on http://localhost:20128"
    fi
  fi

  if (( WITH_LANGFUSE )); then
    local dir="$HOME/.local/share/langfuse"
    if ! has docker; then
      warn "Langfuse needs Docker (Docker Desktop with WSL integration) — skipped"
    else
      [[ -d "$dir/.git" ]] || run git clone --depth 1 https://github.com/langfuse/langfuse.git "$dir"
      run sh -c "cd '$dir' && docker compose up -d"
      ok "Langfuse on http://localhost:3000"
    fi
  fi

  if (( WINDOWS_TOO )); then
    cat <<EOF

  Windows side (only if you also use Claude Code outside WSL). In PowerShell:

    claude plugin marketplace add $REPO
    claude plugin install kit@my-starter-kit
    claude plugin marketplace add DietrichGebert/ponytail;  claude plugin install ponytail@ponytail
    claude plugin marketplace add haydenschmitty/floorplan; claude plugin install floorplan@floorplan
    claude plugin marketplace add addyosmani/agent-skills;  claude plugin install agent-skills@addy-agent-skills
    claude mcp add --scope user context7 -- npx -y @upstash/context7-mcp
    claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest

EOF
  fi

  (( WITH_OMNIROUTE || WITH_LANGFUSE || WINDOWS_TOO )) || ok "none requested"
}

# ---------------------------------------------------------------- main

bold "my-starter-kit — workflow: $WORKFLOW$( (( DRY_RUN )) && echo ' (dry run)')"
step_system
step_plugins
step_code_intel
step_mcp
step_clis
step_global_rules
step_extras

echo
bold "Done. Restart Claude Code, then check with:  claude plugin list && claude mcp list"
bold "In a new repo, run:  /kit:kickoff"
