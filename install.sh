#!/usr/bin/env bash
set -euo pipefail

# Founder OS Installer
# Usage: ./install.sh [--verify] [--skip-notion] [--reset]

# ── Colors & Output ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
info() { echo -e "  ${BLUE}→${NC} $1"; }
header() { echo -e "\n${BOLD}$1${NC}"; }

# ── Flag Parsing ─────────────────────────────────────────────────
VERIFY_ONLY=false
SKIP_NOTION=false
RESET=false

for arg in "$@"; do
  case $arg in
    --verify)      VERIFY_ONLY=true ;;
    --skip-notion) SKIP_NOTION=true ;;
    --reset)       RESET=true ;;
    --help|-h)
      echo "Usage: ./install.sh [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --verify        Run verification checks only (Phase 6)"
      echo "  --skip-notion   Skip Notion HQ database setup (Phase 5)"
      echo "  --reset         Remove installer-generated MCP entries"
      echo "  --help, -h      Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $arg"
      echo "Run ./install.sh --help for usage"
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Reset Mode ───────────────────────────────────────────────────
if $RESET; then
  header "Resetting Founder OS configuration..."

  # Remove installer-generated MCP entries from .mcp.json
  if [ -f "$SCRIPT_DIR/.mcp.json" ] && command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
try:
    with open(sys.argv[1], 'r') as f:
        config = json.load(f)
    for key in ['notion', 'filesystem']:
        config.get('mcpServers', {}).pop(key, None)
    with open(sys.argv[1], 'w') as f:
        json.dump(config, f, indent=2)
        f.write('\n')
    print('Removed notion and filesystem entries from .mcp.json')
except Exception as e:
    print(f'Warning: could not update .mcp.json: {e}', file=sys.stderr)
" "$SCRIPT_DIR/.mcp.json" && ok "Cleaned .mcp.json" || warn "Could not clean .mcp.json"
  fi

  ok "Reset complete. Run ./install.sh to reconfigure."
  exit 0
fi

# ── Phase 1: Prerequisites ──────────────────────────────────────
if ! $VERIFY_ONLY; then
  header "Phase 1: Checking prerequisites..."
  MISSING=()

  # python3 (used for JSON merging and validation)
  if command -v python3 &>/dev/null; then
    ok "python3 available"
  else
    fail "python3 not found"
    MISSING+=("Python 3: https://www.python.org/downloads/")
  fi

  # Node.js >= 18
  if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -ge 18 ]; then
      ok "Node.js $(node --version)"
    else
      fail "Node.js $(node --version) — need v18+"
      MISSING+=("Node.js 18+: https://nodejs.org/")
    fi
  else
    fail "Node.js not found"
    MISSING+=("Node.js 18+: https://nodejs.org/")
  fi

  # npx
  if command -v npx &>/dev/null; then
    ok "npx available"
  else
    fail "npx not found"
    MISSING+=("npx (comes with Node.js): https://nodejs.org/")
  fi

  # Claude Code
  if command -v claude &>/dev/null; then
    ok "Claude Code installed"
  else
    fail "Claude Code not found"
    MISSING+=("Claude Code: https://docs.anthropic.com/en/docs/claude-code")
  fi

  # gws CLI
  if command -v gws &>/dev/null; then
    ok "gws CLI installed"
  else
    fail "gws CLI not found"
    MISSING+=("gws CLI: see docs/getting-started/SETUP-GUIDE.md")
  fi

  if [ ${#MISSING[@]} -gt 0 ]; then
    echo ""
    fail "Missing prerequisites:"
    for item in "${MISSING[@]}"; do
      echo "     - $item"
    done
    echo ""
    echo "Install the missing tools and re-run ./install.sh"
    exit 1
  fi

  ok "All prerequisites met"
fi

# ── Phase 2: Environment Setup ──────────────────────────────────
if ! $VERIFY_ONLY; then
  header "Phase 2: Setting up environment..."

  # Check for .env
  if [ ! -f "$SCRIPT_DIR/.env" ]; then
    cp "$SCRIPT_DIR/.env.example" "$SCRIPT_DIR/.env"
    warn "Created .env from template. Please edit it with your API keys."
    echo ""
    echo "     nano .env    # or use your preferred editor"
    echo ""
    echo "Then re-run: ./install.sh"
    exit 0
  fi

  # Load .env
  set -a
  source "$SCRIPT_DIR/.env"
  set +a

  # Validate NOTION_API_KEY
  if [ -z "${NOTION_API_KEY:-}" ] || [ "$NOTION_API_KEY" = "ntn_your_token_here" ]; then
    echo ""
    warn "NOTION_API_KEY is not set or still has the placeholder value."
    read -rp "  Enter your Notion API key (starts with ntn_): " NOTION_API_KEY
    if [ -z "$NOTION_API_KEY" ]; then
      fail "Notion API key is required. Get one at https://www.notion.so/my-integrations"
      exit 1
    fi
    # Update .env with the provided key
    if grep -q "^NOTION_API_KEY=" "$SCRIPT_DIR/.env"; then
      python3 -c "
import re, sys
key, path = sys.argv[1], sys.argv[2]
with open(path, 'r') as f:
    content = f.read()
content = re.sub(r'^NOTION_API_KEY=.*$', f'NOTION_API_KEY={key}', content, flags=re.MULTILINE)
with open(path, 'w') as f:
    f.write(content)
" "$NOTION_API_KEY" "$SCRIPT_DIR/.env"
    else
      echo "NOTION_API_KEY=$NOTION_API_KEY" >> "$SCRIPT_DIR/.env"
    fi
  fi

  # Validate Notion key against API
  info "Validating Notion API key..."
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    "https://api.notion.com/v1/users/me")

  if [ "$HTTP_STATUS" = "200" ]; then
    ok "Notion API key is valid"
  else
    fail "Notion API key validation failed (HTTP $HTTP_STATUS)"
    echo "     Check that your key starts with 'ntn_' and has the correct capabilities."
    echo "     See docs/getting-started/TROUBLESHOOTING.md for help."
    exit 1
  fi

  # Create WORKSPACE_DIR
  WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/founder-os-workspace}"
  if [ ! -d "$WORKSPACE_DIR" ]; then
    mkdir -p "$WORKSPACE_DIR"
    ok "Created workspace directory: $WORKSPACE_DIR"
  else
    ok "Workspace directory exists: $WORKSPACE_DIR"
  fi

  # Validate SLACK_BOT_TOKEN if provided
  # Note: Slack API always returns HTTP 200; check the JSON "ok" field instead
  if [ -n "${SLACK_BOT_TOKEN:-}" ]; then
    SLACK_RESP=$(curl -s -H "Authorization: Bearer $SLACK_BOT_TOKEN" "https://slack.com/api/auth.test")
    if echo "$SLACK_RESP" | python3 -c "import json,sys; assert json.load(sys.stdin).get('ok')" 2>/dev/null; then
      ok "Slack bot token is valid"
    else
      warn "Slack bot token validation failed — skipping Slack setup"
    fi
  else
    info "Slack bot token not provided — Slack features will be unavailable (optional)"
  fi

  ok "Environment ready"
fi

# ── Phase 3: Google Authentication ──────────────────────────────
if ! $VERIFY_ONLY; then
  header "Phase 3: Google authentication (gws CLI)..."

  # Check if already authenticated
  if gws auth status &>/dev/null; then
    ok "gws CLI already authenticated"
  else
    info "Opening browser for Google authentication..."
    echo "     Sign in with your Google account and approve Gmail, Calendar, and Drive access."
    echo ""

    if ! gws auth login; then
      fail "Google authentication failed."
      echo "     Try: gws auth login --no-browser"
      echo "     See docs/getting-started/TROUBLESHOOTING.md for help."
      exit 1
    fi

    ok "Google authentication successful"
  fi

  # Quick validation
  if gws gmail list --limit=1 &>/dev/null; then
    ok "Gmail access confirmed"
  else
    warn "Could not verify Gmail access — some features may not work"
  fi
fi

# ── Phase 4: Configure MCP ──────────────────────────────────────
if ! $VERIFY_ONLY; then
  header "Phase 4: Configuring MCP servers..."

  # Merge Notion + Filesystem into project-level .mcp.json
  info "Updating project .mcp.json..."
  if command -v python3 &>/dev/null; then
    python3 -c "
import json, os

mcp_path = '$SCRIPT_DIR/.mcp.json'

# Read existing config
config = {'mcpServers': {}}
if os.path.exists(mcp_path):
    with open(mcp_path, 'r') as f:
        config = json.load(f)

servers = config.setdefault('mcpServers', {})

# Add Notion if not present
if 'notion' not in servers:
    servers['notion'] = {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-notion'],
        'env': {
            'NOTION_API_KEY': '\${NOTION_API_KEY}'
        }
    }

# Add Filesystem if not present
if 'filesystem' not in servers:
    servers['filesystem'] = {
        'command': 'npx',
        'args': ['-y', '@modelcontextprotocol/server-filesystem', '\${WORKSPACE_DIR}'],
        'env': {}
    }

with open(mcp_path, 'w') as f:
    json.dump(config, f, indent=2)
    f.write('\n')

print('done')
" "$SCRIPT_DIR" && ok "MCP config: notion + filesystem configured" \
  || { fail "Could not update .mcp.json"; exit 1; }
  else
    fail "python3 is required for .mcp.json configuration"
    exit 1
  fi

  ok "MCP configuration complete"
fi

# ── Phase 5: Notion HQ Setup ────────────────────────────────────
if ! $VERIFY_ONLY && ! $SKIP_NOTION; then
  header "Phase 5: Setting up Notion HQ databases..."

  # Check if databases already exist
  EXISTING_DBS=$(curl -s \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    -X POST "https://api.notion.com/v1/search" \
    -H "Content-Type: application/json" \
    -d '{"query": "[FOS]", "filter": {"property": "object", "value": "database"}}' \
    | python3 -c "import json,sys; data=json.load(sys.stdin); print(len(data.get('results',[])))" 2>/dev/null || echo "0")

  if [ "$EXISTING_DBS" -ge 22 ]; then
    ok "Notion HQ databases already exist ($EXISTING_DBS found)"
  else
    info "Found $EXISTING_DBS existing databases. Setting up remaining..."

    # Try invoking Claude Code to run /setup:notion-hq
    if command -v claude &>/dev/null; then
      info "Running /setup:notion-hq via Claude Code (this may take a few minutes)..."
      if claude -p "Run /setup:notion-hq to create all Founder OS HQ Notion databases. Use the notion-hq-setup skill. Read the manifest at _infrastructure/notion-db-templates/founder-os-hq-manifest.json and create any missing databases." --dangerously-skip-permissions 2>/dev/null; then
        ok "Notion HQ setup complete"
      else
        warn "Automated Notion setup did not complete successfully."
        echo ""
        echo "     Please run this manually in Claude Code:"
        echo "     ${BOLD}/setup:notion-hq${NC}"
        echo ""
        echo "     This will create the 22 Notion databases needed by Founder OS."
        echo ""
      fi
    else
      warn "Claude Code not available for automated Notion setup."
      echo ""
      echo "     Open Claude Code in this project and run: /setup:notion-hq"
      echo ""
    fi
  fi
elif $SKIP_NOTION; then
  info "Skipping Notion HQ setup (--skip-notion flag)"
fi

# ── Phase 6: Verification ───────────────────────────────────────
header "Phase 6: Verifying installation..."

PASS=0
TOTAL=0

# Load .env if not already loaded
if [ -z "${NOTION_API_KEY:-}" ] && [ -f "$SCRIPT_DIR/.env" ]; then
  set -a
  source "$SCRIPT_DIR/.env"
  set +a
fi

# 1. Notion connectivity
TOTAL=$((TOTAL + 1))
if [ -n "${NOTION_API_KEY:-}" ] && [ "$NOTION_API_KEY" != "ntn_your_token_here" ]; then
  NOTION_CHECK=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $NOTION_API_KEY" \
    -H "Notion-Version: 2022-06-28" \
    "https://api.notion.com/v1/users/me")
  if [ "$NOTION_CHECK" = "200" ]; then
    ok "Notion API: connected"
    PASS=$((PASS + 1))
  else
    fail "Notion API: connection failed (HTTP $NOTION_CHECK)"
  fi
else
  fail "Notion API: not configured"
fi

# 2. gws connectivity
TOTAL=$((TOTAL + 1))
if command -v gws &>/dev/null && gws auth status &>/dev/null; then
  ok "gws CLI: authenticated"
  PASS=$((PASS + 1))
else
  fail "gws CLI: not authenticated"
fi

# 3. Plugin commands
TOTAL=$((TOTAL + 1))
CMD_COUNT=$(find "$SCRIPT_DIR/commands" -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$CMD_COUNT" -ge 90 ]; then
  ok "Commands: $CMD_COUNT found"
  PASS=$((PASS + 1))
elif [ "$CMD_COUNT" -gt 0 ]; then
  warn "Commands: only $CMD_COUNT found (expected 94+)"
else
  fail "Commands: no command files found in commands/"
fi

# 4. .mcp.json has required entries
TOTAL=$((TOTAL + 1))
if [ -f "$SCRIPT_DIR/.mcp.json" ]; then
  if python3 -c "
import json
with open('$SCRIPT_DIR/.mcp.json') as f:
    c = json.load(f)
s = c.get('mcpServers', {})
assert 'notion' in s, 'missing notion'
assert 'filesystem' in s, 'missing filesystem'
" 2>/dev/null; then
    ok "MCP config: notion + filesystem present"
    PASS=$((PASS + 1))
  else
    fail "MCP config: missing notion or filesystem entries"
  fi
else
  fail "MCP config: .mcp.json not found"
fi

# 5. Workspace directory
TOTAL=$((TOTAL + 1))
WORKSPACE_DIR="${WORKSPACE_DIR:-$HOME/founder-os-workspace}"
if [ -d "$WORKSPACE_DIR" ]; then
  ok "Workspace: $WORKSPACE_DIR exists"
  PASS=$((PASS + 1))
else
  fail "Workspace: $WORKSPACE_DIR not found"
fi

# Summary
echo ""
if [ $PASS -eq $TOTAL ]; then
  echo -e "${GREEN}${BOLD}Installation complete! $PASS/$TOTAL checks passed.${NC}"
  echo ""
  echo "  Next steps:"
  echo "    1. Open Claude Code in this directory"
  echo "    2. Try: /inbox:triage"
  echo "    3. Try: /report:generate --type=weekly"
  echo "    4. Try: /client:load --company=\"Acme Corp\""
  echo ""
  echo "  Docs: docs/getting-started/SETUP-GUIDE.md"
  echo "  FAQ:  docs/getting-started/FAQ.md"
  echo "  Help: docs/getting-started/TROUBLESHOOTING.md"
else
  echo -e "${YELLOW}${BOLD}Installation partially complete: $PASS/$TOTAL checks passed.${NC}"
  echo ""
  echo "  See docs/getting-started/TROUBLESHOOTING.md for help with failing checks."
  echo "  Re-run: ./install.sh --verify"
fi
