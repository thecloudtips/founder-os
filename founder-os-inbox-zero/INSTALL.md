# Installation Guide: Inbox Zero Commander

> AI-powered email triage that categorizes, prioritizes, extracts actions, drafts responses, and archives — achieving Inbox Zero with a 4-agent pipeline.

## Prerequisites

- [ ] Claude Desktop with the **Code** tab enabled
- [ ] `gws` CLI installed and authenticated

### Connectors

| Service | Required? | How |
|---------|-----------|-----|
| **Gmail** | Required | Via `gws` CLI — install gws, then run `gws auth login` to authenticate with your Google account |
| **Notion** | Optional | Enable native connector in Claude Desktop Settings > Integrations. Deploy the Founder OS HQ template for consolidated Tasks and Content databases. |

## Installation

1. Zip the `founder-os-inbox-zero/` folder
2. Upload the zip in Claude Desktop's Code tab

## gws CLI Setup

1. Install the gws CLI tool (see your organization's gws installation guide)
2. Authenticate with Google:
   ```bash
   gws auth login
   ```
3. Verify Gmail access:
   ```bash
   gws gmail +triage --max 5 --format json
   ```
   You should see a JSON summary of your recent unread emails.

## Verify

```
/founder-os-inbox-zero:inbox-triage
```

The plugin fetches your Gmail inbox via gws CLI and presents a categorized summary.

## How it works

This plugin uses the `gws` CLI to access your Gmail:
- Runs `gws gmail` commands to list, read, label, and draft emails
- Requires a one-time `gws auth login` to authenticate
- Works with any Google account authorized via gws
- No separate OAuth setup, API keys, or browser extensions needed

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Unknown skill" error | Re-upload the plugin zip, restart Claude Desktop |
| "gws CLI not found" | Install gws and ensure it is on your PATH |
| "gws auth" errors | Run `gws auth login` to re-authenticate |
| No emails found | Try `--hours=48` to expand the lookback window |
