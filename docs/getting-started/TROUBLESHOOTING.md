# Founder OS — Troubleshooting Guide

Each entry follows: **Symptom → Cause → Fix → Verify**

## Installation Issues

### "Plugin has an invalid manifest" during install

**Symptom:** `claude plugin install founder-os` fails with a manifest validation error.

**Cause:** The marketplace cache may have a stale version.

**Fix:**
```bash
claude plugin marketplace remove founder-os-marketplace
claude plugin marketplace add thecloudtips/founder-os
claude plugin install founder-os
```

**Verify:** Plugin installs without errors.

---

### "Node.js not found" or MCP servers fail to start

**Symptom:** Notion or Filesystem MCP servers don't connect.

**Cause:** Node.js is not installed or is an older version. MCP servers require Node.js 18+.

**Fix:**
1. Install Node.js 18+ from https://nodejs.org/ (LTS recommended)
2. If installed via nvm: `nvm install 18 && nvm use 18`
3. Restart your terminal

**Verify:** `node --version` shows v18.x or higher.

---

### "Claude Code not found"

**Symptom:** `claude` command not recognized.

**Cause:** Claude Code CLI is not installed or not in PATH.

**Fix:** Install Claude Code following https://docs.anthropic.com/en/docs/claude-code

**Verify:** `claude --version` outputs a version number.

---

## Notion Issues

### "NOTION_API_KEY not set" or Notion commands fail

**Symptom:** Commands that use Notion return errors about missing API key.

**Cause:** The `NOTION_API_KEY` environment variable is not set in your shell.

**Fix:**
```bash
# Add to ~/.zshrc (macOS) or ~/.bashrc (Linux)
export NOTION_API_KEY=ntn_your_token_here

# Reload
source ~/.zshrc
```

**Verify:** `echo $NOTION_API_KEY` shows your key. Restart Claude Code and retry.

---

### "Notion API key validation failed"

**Symptom:** Notion commands fail with HTTP 401 or 403.

**Cause:** The API key is invalid, expired, or missing capabilities.

**Fix:**
1. Verify your key starts with `ntn_`
2. Go to https://www.notion.so/my-integrations
3. Click on your "Founder OS" integration
4. Check that all capabilities are enabled (Read, Update, Insert content)
5. If the key looks wrong, create a new integration and update your env var

**Verify:** Run `/founder-os:setup:verify` — Notion check should pass.

---

### "Database not found" or missing databases

**Symptom:** `/founder-os:setup:verify` shows fewer than 22 databases, or commands report "database not found".

**Cause:** Notion HQ setup didn't complete, or the integration doesn't have access.

**Fix:**
1. Run `/founder-os:setup:notion-hq` in Claude Code (creates missing databases — it's idempotent)
2. If databases exist but aren't found: open the Founder OS HQ page in Notion → Click **...** → **Connections** → Ensure your "Founder OS" integration is connected

**Verify:** Run `/founder-os:setup:verify` — should show 22/22 databases.

---

### Notion rate limiting

**Symptom:** Database creation fails with "rate limited" or HTTP 429 errors.

**Cause:** Notion API allows ~3 requests/second. Batch operations can exceed this.

**Fix:** Wait 60 seconds and re-run `/founder-os:setup:notion-hq`. It's idempotent — it picks up where it left off.

**Verify:** Run `/founder-os:setup:verify` — should show 22/22 databases.

---

## Google (gws) Issues

### "gws CLI not found"

**Symptom:** Google-dependent commands fail, or `gws --version` returns nothing.

**Cause:** The gws CLI tool is not installed. This is optional — only needed for 20 namespaces that use Gmail, Calendar, or Drive.

**Fix:** Follow gws CLI installation instructions for your platform.

**Verify:** `gws --version` outputs a version number.

---

### "Google authentication failed"

**Symptom:** Google commands fail after `gws auth login`.

**Cause:** Browser didn't open, wrong account selected, or scopes not approved.

**Fix:**
1. Try headless auth: `gws auth login --no-browser` (gives you a URL to paste)
2. Make sure you approve Gmail, Calendar, AND Drive access
3. Use the correct Google account (the one with your work email)

**Verify:** `gws auth status` shows authenticated. `gws gmail list --limit=1` returns a result.

---

## Plugin & Command Issues

### Commands not recognized

**Symptom:** Slash commands like `/founder-os:inbox:triage` aren't recognized in Claude Code.

**Cause:** Plugin not installed, or Claude Code needs a restart.

**Fix:**
1. Verify the plugin is installed: check that `founder-os@founder-os-marketplace` appears in `~/.claude/plugins/installed_plugins.json`
2. Restart Claude Code (close and reopen)
3. If still not working, reinstall:
   ```bash
   claude plugin marketplace remove founder-os-marketplace
   claude plugin marketplace add thecloudtips/founder-os
   claude plugin install founder-os
   ```

**Verify:** Open Claude Code and type `/founder-os:` — autocomplete should show available commands.

---

### "MCP server connection failed"

**Symptom:** Commands fail with MCP connection errors for Notion or Filesystem.

**Cause:** The plugin's `.mcp.json` isn't being picked up, or environment variables aren't set.

**Fix:**
1. Verify `NOTION_API_KEY` is set: `echo $NOTION_API_KEY`
2. Restart Claude Code to reload MCP configuration
3. Check that Node.js 18+ is installed (MCP servers need it)

**Verify:** Run `/founder-os:setup:verify` — MCP checks should pass.

---

## Memory & Intelligence Issues

### Memory or intelligence features not working

**Symptom:** Commands don't seem to remember context or adapt behavior.

**Cause:** The local SQLite databases haven't been created yet, or they're in a different project directory.

**Fix:** Memory and intelligence databases are created per-project on first use. Run any command that uses memory (e.g., `/founder-os:memory:show`) to initialize the memory store. The intelligence store initializes when hooks first fire.

**Verify:** Check that `.memory/memory.db` exists in your project root after running a memory command.

---

### Want to start fresh with memory/intelligence?

**Fix:**
```bash
# Reset memory
rm -rf .memory/

# Reset intelligence
rm -rf .intelligence/
```

Both will be re-created automatically on next use.

---

## Environment Issues

### Workspace directory permission errors

**Symptom:** File-based commands (Report Generator, Contract Analyzer) fail to write output.

**Cause:** The workspace directory (`~/founder-os-workspace` by default) doesn't exist or has wrong permissions.

**Fix:**
```bash
mkdir -p ~/founder-os-workspace
chmod 755 ~/founder-os-workspace
```

**Verify:** `ls -la ~/founder-os-workspace` shows the directory with write permissions.
