---
name: gws-common
description: Core gws CLI conventions for Founder OS plugins. Use this skill whenever working with any Google Workspace data (Gmail, Calendar, Drive) in any Founder OS plugin. Covers authentication checks, output formatting, error handling, and rate limit awareness.
---

## Overview

The `gws` CLI tool replaces all Google MCP servers (Gmail, Calendar, Drive) across Founder OS plugins. This skill covers the shared conventions that apply to ALL gws commands regardless of service.

## Prerequisites

Before any gws operation, verify the CLI is available:

```bash
which gws || echo "gws CLI not installed — skipping Google data"
```

If `gws` is not found, the plugin MUST degrade gracefully: skip Google data sources, note them as `status: "unavailable"` in output, and continue with remaining data sources.

## Global Conventions

### Output Format

Always use `--format json` for machine-readable output:

```bash
gws gmail users messages list --params '{"userId":"me","q":"is:unread","maxResults":10}' --format json
```

Parse JSON output with `jq` or inline parsing. Never rely on human-readable text output.

### Error Handling

| Exit Code | Meaning | Action |
|-----------|---------|--------|
| 0 | Success | Parse JSON output |
| 1 | General error | Log error, degrade gracefully |
| Non-zero | Auth expired, rate limit, network | Retry once after 2s, then degrade |

Check exit codes explicitly:

```bash
result=$(gws gmail +triage --max 10 --format json 2>/tmp/gws-error.log)
if [ $? -ne 0 ]; then
  echo "Gmail unavailable: $(cat /tmp/gws-error.log)"
  # Continue without Gmail data
fi
```

### Rate Limit Awareness

Google APIs have per-user rate limits. When making many sequential calls:
- Add 100ms delays between calls in tight loops
- Batch where possible (e.g., fetch multiple message IDs in one query)
- If rate-limited, back off exponentially (2s, 4s, 8s)

### Authentication

gws handles authentication automatically via stored credentials. No per-plugin credential configuration is needed. If auth expires, gws will prompt for re-authentication.

### FOS Integration Patterns

- All gws output should be parsed and transformed to match the plugin's existing output contract (JSON structure)
- Use `--format json` and pipe through `jq` for field extraction
- Graceful degradation: if gws unavailable, set `status: "unavailable"` for that data source and continue
- Never hard-fail a plugin because a Google data source is unavailable
