# Founder OS — Troubleshooting Guide

Each entry follows: **Symptom → Cause → Fix → Verify**

## Installation Issues

### "Permission denied" when running install.sh

**Symptom:** `bash: ./install.sh: Permission denied`

**Cause:** The script doesn't have execute permissions.

**Fix:**
```bash
chmod +x install.sh
./install.sh
```

**Verify:** Script starts running and shows "Phase 1: Checking prerequisites..."

---

### "Node.js not found" or "need v18+"

**Symptom:** Phase 1 fails with Node.js error.

**Cause:** Node.js is not installed or is an older version.

**Fix:**
1. Install Node.js 18+ from https://nodejs.org/ (LTS recommended)
2. If installed via nvm: `nvm install 18 && nvm use 18`
3. Restart your terminal

**Verify:** `node --version` shows v18.x or higher.

---

### "npx not found"

**Symptom:** Phase 1 fails with npx error.

**Cause:** npx comes bundled with Node.js. If missing, Node.js may be partially installed.

**Fix:** Reinstall Node.js from https://nodejs.org/

**Verify:** `npx --version` outputs a version number.

---

### "Claude Code not found"

**Symptom:** Phase 1 fails with Claude Code error.

**Cause:** Claude Code CLI is not installed or not in PATH.

**Fix:** Install Claude Code following https://docs.anthropic.com/en/docs/claude-code

**Verify:** `claude --version` outputs a version number.

---

### "gws CLI not found"

**Symptom:** Phase 1 fails with gws error.

**Cause:** The gws CLI tool is not installed.

**Fix:** Follow gws CLI installation instructions for your platform.

**Verify:** `gws --version` outputs a version number.

---

## Notion Issues

### "Notion API key validation failed"

**Symptom:** Phase 2 fails with HTTP 401 or 403.

**Cause:** The API key is invalid, expired, or missing capabilities.

**Fix:**
1. Verify your key starts with `ntn_`
2. Go to https://www.notion.so/my-integrations
3. Click on your "Founder OS" integration
4. Check that all capabilities are enabled (Read, Update, Insert content)
5. If the key looks wrong, create a new integration and update `.env`

**Verify:** Re-run `./install.sh` — Phase 2 should show "Notion API key is valid".

---

### "Database not found" or missing databases

**Symptom:** `/setup:verify` shows fewer than 22 databases, or plugins report "database not found".

**Cause:** Notion HQ setup didn't complete, or the integration doesn't have access.

**Fix:**
1. Run `/setup:notion-hq` in Claude Code (creates missing databases)
2. If databases exist but aren't found: open the Founder OS HQ page in Notion → Click **...** → **Connections** → Ensure your integration is connected

**Verify:** Run `/setup:verify` — should show 22/22 databases.

---

### Notion rate limiting

**Symptom:** Database creation fails with "rate limited" or HTTP 429 errors.

**Cause:** Notion API allows ~3 requests/second. Batch operations can exceed this.

**Fix:** Wait 60 seconds and re-run `/setup:notion-hq`. It's idempotent — it picks up where it left off.

**Verify:** Run `/setup:verify` — should show 22/22 databases.

---

## Google (gws) Issues

### "Google authentication failed"

**Symptom:** Phase 3 fails after `gws auth login`.

**Cause:** Browser didn't open, wrong account selected, or scopes not approved.

**Fix:**
1. Try headless auth: `gws auth login --no-browser` (gives you a URL to paste)
2. Make sure you approve Gmail, Calendar, AND Drive access
3. Use the correct Google account (the one with your work email)

**Verify:** `gws auth status` shows authenticated. `gws gmail list --limit=1` returns a result.

---

### "Could not verify Gmail access"

**Symptom:** Phase 3 warning about Gmail access.

**Cause:** Gmail API access wasn't granted, or the account has no emails.

**Fix:**
1. Re-run `gws auth login` and ensure Gmail scope is approved
2. Check Google API console for any restrictions on your account

**Verify:** `gws gmail list --limit=1` returns at least one email.

---

## Plugin Issues

### Plugins not showing in Claude Code

**Symptom:** Slash commands like `/inbox:triage` aren't recognized.

**Cause:** Symlinks are missing or Claude Code needs a restart.

**Fix:**
1. Check symlinks exist: `ls -la .claude/plugins/`
2. If empty, re-run `./install.sh`
3. Restart Claude Code (close and reopen)

**Verify:** Open Claude Code and type `/inbox:` — autocomplete should show available commands.

---

### "MCP server connection failed"

**Symptom:** Plugin commands fail with MCP connection errors.

**Cause:** `.mcp.json` is missing server entries, or environment variables aren't set.

**Fix:**
1. Check `.mcp.json` has `notion` and `filesystem` entries: `cat .mcp.json`
2. Verify `.env` has `NOTION_API_KEY` and `WORKSPACE_DIR` set
3. Re-run `./install.sh` to regenerate MCP config

**Verify:** Run `/setup:verify` — MCP Config check should pass.

---

### Broken symlinks after moving the repository

**Symptom:** Plugins stop working after moving the founderOS directory.

**Cause:** Symlinks use absolute paths that break when the repo moves.

**Fix:**
```bash
./install.sh --reset
./install.sh
```

**Verify:** `ls -la .claude/plugins/` shows valid symlinks pointing to the new location.

---

## Environment Issues

### ".env file not found" on re-run

**Symptom:** Installer creates a new `.env` from template and exits.

**Cause:** `.env` file was deleted or never created.

**Fix:** The installer automatically creates `.env` from `.env.example`. Edit it with your API keys and re-run.

**Verify:** `cat .env` shows your actual API keys (not placeholder values).

---

### Workspace directory permission errors

**Symptom:** File-based plugins (Report Generator, Contract Analyzer) fail to write output.

**Cause:** `WORKSPACE_DIR` doesn't exist or has wrong permissions.

**Fix:**
```bash
mkdir -p ~/founder-os-workspace
chmod 755 ~/founder-os-workspace
```

**Verify:** `ls -la ~/founder-os-workspace` shows the directory with write permissions.
