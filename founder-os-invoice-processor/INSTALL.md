# Installation: Invoice Processor

## Prerequisites

- Claude Code with plugin support
- Node.js 18+ (for MCP servers via `npx`)
- Notion account with API access

## Step 1: Install Required MCP Servers

### Filesystem Server (Required)

```bash
npx -y @modelcontextprotocol/server-filesystem /path/to/your/invoices
```

The filesystem server provides read access to your invoice files. Pass the root directory where invoices are stored.

### Notion Server (Required)

```bash
npx -y @modelcontextprotocol/server-notion
```

**Configure Notion API Key:**

1. Go to [notion.so/my-integrations](https://notion.so/my-integrations)
2. Click "New integration" → name it "Invoice Processor"
3. Copy the Internal Integration Token
4. Set the environment variable:

```bash
export NOTION_API_KEY="your_notion_api_key_here"
```

5. Share your Notion workspace (or specific databases) with the integration:
   - Open any Notion page → click "..." → "Add connections" → select "Invoice Processor"

## Step 2: Install gws CLI (Optional — for Gmail and Google Drive access)

The gws CLI provides access to Gmail (invoice attachments) and Google Drive (invoice files stored in Drive).

```bash
# Verify gws is installed
which gws || echo "gws CLI not available — install from https://github.com/tmc/gws"

# Authenticate with Google
gws auth login
```

Once authenticated, you can search Gmail for invoice attachments and access invoices stored in Google Drive directly via Bash commands.

## Step 3: Configure Environment

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
# Invoice Processor — Required
export NOTION_API_KEY="your_notion_api_key_here"
```

## Step 4: Enable the Plugin

In Claude Code, enable the plugin from your plugin manager or by adding the plugin directory to your configuration.

## Step 5: Verify Installation

Test with a sample invoice:

```bash
/invoice:process /path/to/any-invoice.pdf
```

You should see an extracted invoice summary. No Notion write happens in default mode.

For full pipeline test:

```bash
/invoice:process /path/to/any-invoice.pdf --team
```

You should see a Notion record URL at the end.

## Notion Databases

This plugin writes to the consolidated **"Founder OS HQ - Finance"** database with `Type = "Invoice"`. If the HQ database is not found, it falls back to the legacy "Invoice Processor - Invoices" database.

- **Founder OS HQ - Finance** (preferred): Consolidated finance database shared across plugins. Each invoice record has `Type = "Invoice"`. Approval requests use `Type = "Approval"`.
- **Invoice Processor - Invoices** (legacy fallback): Standalone database used if the HQ template has not been deployed.

The plugin does **not** auto-create either database. Deploy the HQ template first — see `_infrastructure/notion-db-templates/founder-os-hq-finance.json`.

Vendor names are linked to the **Companies** database (from the CRM Pro template) via a Company relation when a match is found.

## Troubleshooting

**"Notion API key not configured"**
→ Check `echo $NOTION_API_KEY` returns your key. Re-run `source ~/.zshrc`.

**"File not found"**
→ Ensure the filesystem MCP server has access to the invoice directory. Check the path passed to `@modelcontextprotocol/server-filesystem`.

**"gws CLI not available"**
→ Install the gws CLI tool and authenticate with `gws auth login`.

**"Unsupported format"**
→ Only PDF, JPG, JPEG, PNG, TIFF are supported. Convert other formats first.

**Notion integration not connecting**
→ Verify the integration has been shared with your Notion workspace/pages via "Add connections".
