# Quick Start: Learning Log Tracker (#29)

Get started in 3 minutes. These examples show the core workflow: capture → search → review.

---

## 1. Capture Your First Learning

```
/learn:log "Discovered that batch processing Notion API calls with 10-item chunks reduces rate limit errors by 90%"
```

**Expected output:**
```
✅ Learning captured!

📝 Batch Processing Reduces Notion API Rate Limits
🏷️ Topics: Technical, Tool
📖 Source: Experience
📅 Week: 2026-W10

🔗 No related past insights found yet. Keep logging — connections build over time!

Use /learn:search to find past learnings | /learn:weekly for your weekly summary
```

---

## 2. Capture with Source and Context

```
/learn:log "Reading about the PARA method changed how I think about organizing project notes" --source=reading --context="Tiago Forte's Building a Second Brain"
```

**Expected output:**
```
✅ Learning captured!

📝 PARA Method Transforms Project Note Organization
🏷️ Topics: Process, Tool
📖 Source: Reading
📅 Week: 2026-W10

🔗 Related Insights:
  • Batch Processing Reduces Notion API Rate Limits

Use /learn:search to find past learnings | /learn:weekly for your weekly summary
```

---

## 3. Search Your Learnings

### By topic:
```
/learn:search Technical
```

### By keyword with date filter:
```
/learn:search "API" --since=30d
```

### Most recent (no filters):
```
/learn:search
```

**Expected output:**
```
### 🔍 Learning Search Results

**Query**: Technical | **Filters**: topic=Technical | **Results**: 2 found

1. 📘 **Batch Processing Reduces Notion API Rate Limits** — Technical, Tool
   _Discovered that batch processing Notion API calls with 10-item chunks..._
   📅 2026-03-05 | Source: Experience
   🔗 Related: PARA Method Transforms Project Note Organization

2. 📘 **Granular Try-Catch Blocks for Async Errors** — Technical, Process
   _Today I realized that async error handling works much better when..._
   📅 2026-03-03 | Source: Experience
   🔗 Related: none
```

---

## 4. Generate Your Weekly Summary

```
/learn:weekly
```

**Expected output:**
```
## 📊 Weekly Learning Insights — 2026-W10

**5 learnings** logged this week | Streak: 3 weeks 📚 | Same pace

### 🎯 Top Themes
Technical, Process, Tool
Most active: Technical (3 learnings)

### 📝 Summary
A technically-focused week with 5 learnings spanning API optimization, note organization, and team workflows. The dominant Technical theme suggests active hands-on development work. Your PARA method insight from reading connected with practical Notion API discoveries — theory meeting practice.

### 🔗 Key Connections
- Your Technical insight about batch processing reinforced your Tool learning about PARA method — both point toward systematic approaches to managing information flow.
- Your Process insight about code reviews connected with your People learning about delegation — both emphasize catching issues before they escalate.

### 📋 All Learnings
• Batch Processing Reduces Notion API Rate Limits (Mon)
• PARA Method Transforms Project Note Organization (Tue)
• Granular Try-Catch Blocks for Async Errors (Wed)
• Kickoff Questionnaires Reduce Client Scope Creep (Thu)
• Weekly Retros Improve Team Velocity (Fri)

### 📊 Source Mix
Experience: 3, Reading: 1, Conversation: 1
```

---

## 5. Review a Past Week

```
/learn:weekly --week=2026-W09
```

---

## Tips for Effective Learning Capture

- **Log insights as they happen** — don't wait until end of day
- **Be specific** — "Batch processing with 10-item chunks" beats "API optimization"
- **Include source** — `--source=reading` or `--source=conversation` adds context
- **Add context** — `--context="Sprint retro meeting"` links learnings to situations
- **Review weekly** — `/learn:weekly` reveals patterns you won't notice day-to-day
