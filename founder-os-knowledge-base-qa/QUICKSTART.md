# Quick Start: Knowledge Base Q&A

> Search your Notion workspace and Google Drive for sourced answers with citations.

**Plugin #23** | **Pillar**: MCP & Integrations | **Platform**: Claude Code

### What This Plugin Does

- Answers questions using your Notion pages and Google Drive documents as sources
- Cites every factual claim with numbered references to source documents
- Finds and previews relevant documents by topic
- Indexes and classifies all your knowledge sources with freshness tracking

### Time Savings

Estimated **15-25 minutes** per lookup session compared to manually searching Notion and Drive.

## Available Commands

| Command | Description |
|---------|-------------|
| `/kb:ask [question]` | Get a sourced answer with citations |
| `/kb:find [topic]` | Browse documents matching a topic |
| `/kb:index` | Catalog all knowledge sources |

## Usage Examples

### Example 1: Ask a Question

```
/kb:ask "What is our refund policy?"
```

**What happens:** Searches Notion and Drive for refund-related documents, synthesizes an answer with inline citations [1][2], and shows confidence level (High/Medium/Low). Logs the query to Notion for tracking.

### Example 2: Ask with Source Filter

```
/kb:ask "How do we handle client onboarding?" --sources=notion
```

**What happens:** Searches only Notion (skips Drive). Useful when you know the answer lives in Notion, or when Drive isn't configured.

### Example 3: Find Documents on a Topic

```
/kb:find "employee handbook"
```

**What happens:** Returns a list of up to 10 documents matching "employee handbook" with title, preview excerpt, classification, freshness, and relevance score. No Notion logging — this is a lightweight browse.

### Example 4: Find by Type

```
/kb:find "deployment" --type=process --limit=5
```

**What happens:** Searches only for documents classified as "process" type, limiting to 5 results. Useful for finding SOPs and step-by-step guides.

### Example 5: Index Your Knowledge Base

```
/kb:index
```

**What happens:** Crawls all Notion pages and Google Drive documents accessible to the integration. Classifies each source (wiki, meeting-notes, project-docs, etc.), computes freshness, extracts keywords, and saves the catalog to the "[FOS] Knowledge Base" Notion database with Type="Source" (falls back to "Founder OS HQ - Knowledge Base", then legacy "Knowledge Base Q&A - Sources").

### Example 6: Index Notion Only

```
/kb:index --scope=notion
```

**What happens:** Indexes only Notion sources. Faster than full index when you only need Notion content cataloged.

## Tips

- Run `/kb:index` once before using `/kb:ask` — the Sources catalog helps prioritize search results
- Use `/kb:find` for quick document discovery, `/kb:ask` for actual answers with citations
- Share more Notion pages with the integration to expand the searchable knowledge base
- The plugin handles "I don't know" gracefully — when it can't find an answer, it suggests related docs and alternative search terms

## Troubleshooting

| Issue | Solution |
|-------|----------|
| No results found | Share Notion pages with the integration via Connections menu |
| Low confidence answers | Run `/kb:index` to update the source catalog, or try more specific questions |
| "Notion MCP server is not connected" | Check `NOTION_API_KEY` environment variable |
| Google Drive not searched | Install gws CLI and run `gws auth login` (Drive is optional) |

## Next Steps

1. Run `/kb:index` to catalog your knowledge base
2. Try `/kb:ask` with questions about your business processes
3. Use `/kb:find` to discover documents you may have forgotten about
4. Check `INSTALL.md` for advanced configuration options
