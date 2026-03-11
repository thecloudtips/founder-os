# Citation Formats and Answer Synthesis Reference

Detailed specifications for citation formatting, confidence scoring, no-answer templates, conflict reconciliation, and answer length guidelines. Referenced by `${CLAUDE_PLUGIN_ROOT}/skills/kb/answer-synthesis/SKILL.md`.

---

## Citation Format Specification

### Inline Citation Placement

**End-of-sentence citation** (cites the entire sentence):
```
The onboarding process requires three completed forms. [1]
```

**Mid-sentence citation** (cites a specific clause):
```
While the free tier allows up to 5 users [1], the Pro plan removes
all seat limits [2].
```

**Multi-citation** (multiple sources support the same claim):
```
All data exports are available in CSV and JSON formats. [1][3]
```

**Citation within a list**:
```
- Maximum file upload size: 50 MB [1]
- Supported formats: PDF, DOCX, XLSX, CSV [2]
- Retention period: 90 days for free tier, unlimited for paid [1][3]
```

### Citation Block Format

Place the citation block after a horizontal rule at the end of the answer:

```
---
Sources:
[1] "Getting Started Guide" - https://notion.so/workspace/getting-started-abc123
[2] "File Upload Limits" - https://docs.google.com/document/d/xyz789
[3] "Pricing and Plans" - Notion DB: Company Wiki
```

#### Source Type Formats

| Source Type | Format |
|-------------|--------|
| Notion page | `"Page Title" - https://notion.so/...` |
| Notion DB entry | `"Entry Title" - Notion DB: Database Name` |
| Google Drive doc | `"Document Title" - https://docs.google.com/...` |
| Google Drive file | `"File Name" - Google Drive: /path/to/file` |
| Untitled source | `"[Untitled]" - https://notion.so/...` |
| Source with section | `"Document Title > Section Name" - URL` |

#### Citation Numbering Rules

1. Number citations sequentially in the order they first appear in the answer text (not by relevance or alphabetical order).
2. Reuse the same number when referencing the same source again later in the answer.
3. Maximum 5 unique citations per answer. Select the most relevant and authoritative sources when more are available.
4. Never assign a citation number that is not used in the answer text. If only 3 sources are cited, the block lists [1], [2], [3] only.

---

## Confidence Threshold Criteria

### Scoring Framework

Evaluate confidence across four dimensions. Each dimension contributes to the final confidence level.

| Dimension | High Signal | Medium Signal | Low Signal |
|-----------|-------------|---------------|------------|
| **Source agreement** | 2+ sources converge on the same answer | 1 strong source, or 2+ partial sources | Weak matches only, or sources disagree |
| **Keyword match** | Question terms appear in source titles or headings | Question terms appear in source body text | Only synonyms or tangential terms match |
| **Recency** | Primary source updated within 90 days | Primary source updated within 180 days | Primary source older than 180 days |
| **Directness** | Source explicitly answers the question | Source contains the answer but requires extraction | Answer requires inference across sources |

### Confidence Decision Matrix

| Source Agreement | Keyword Match | Recency | Directness | Confidence |
|-----------------|---------------|---------|------------|------------|
| High | High | High | High | **High** |
| High | High | Medium | High | **High** |
| High | Medium | High | High | **High** |
| Medium | High | High | High | **Medium** |
| High | High | Low | High | **Medium** |
| Medium | Medium | Medium | Medium | **Medium** |
| Low | Any | Any | Any | **Low** |
| Any | Low | Low | Any | **Low** |
| Any | Any | Any | Low | **Low** (max) |

When the matrix does not produce a clear result, use the lowest applicable level. Err toward under-confidence rather than over-confidence.

### Single-Source Override

When only one source is available:
- Maximum confidence is **Medium**, even if all other signals are High.
- Exception: A single official policy page updated within the last 30 days that explicitly and completely answers the question may be rated **High**.

### Worked Example: High Confidence

**Question**: "What is the maximum file upload size?"

**Sources retrieved**:
1. "Upload Limits" (updated 2 weeks ago, relevance 0.92) -- states "Maximum upload size is 50 MB per file."
2. "Getting Started FAQ" (updated 1 month ago, relevance 0.85) -- states "Files up to 50 MB can be uploaded."
3. "API Documentation" (updated 3 months ago, relevance 0.71) -- states "max_file_size: 52428800 bytes (50 MB)."

**Assessment**: Three sources agree (50 MB). Strong keyword match ("upload size" in source titles). All sources within 90 days. Sources explicitly answer the question.
**Confidence**: **High**

### Worked Example: Medium Confidence

**Question**: "Can I export my data to Excel?"

**Sources retrieved**:
1. "Data Export Guide" (updated 4 months ago, relevance 0.88) -- states "Export formats: CSV, JSON, PDF."
2. "Release Notes v2.3" (updated 6 months ago, relevance 0.61) -- mentions "Added XLSX export for reporting module."

**Assessment**: One source says CSV/JSON/PDF (no Excel). Another mentions XLSX but only for the reporting module. Partial agreement with a scope difference. Primary source is 4 months old. Answer requires combining two sources.
**Confidence**: **Medium**

### Worked Example: Low Confidence

**Question**: "What is our SLA for critical incidents?"

**Sources retrieved**:
1. "Team Handbook" (updated 14 months ago, relevance 0.45) -- mentions "We aim to respond to critical issues within 4 hours."
2. "Client Onboarding Deck" (updated 8 months ago, relevance 0.38) -- states "24/7 support with 1-hour response for critical incidents."

**Assessment**: Two sources disagree (4 hours vs 1 hour). Both are stale. Neither is an official SLA document. Weak keyword matches (no source titled "SLA"). Answer requires choosing between conflicting information.
**Confidence**: **Low**

---

## No-Answer Response Templates

### Template 1: No Relevant Sources

Use when zero sources pass the relevance filter.

```
**Confidence:** N/A

I could not find a definitive answer to "[user question]" in the
knowledge base.

No documents were found that directly address this topic.

**Try searching for:**
- [synonym or broader term 1]
- [related concept 2]
- [alternative phrasing 3]

Would you like me to search again with different keywords?
```

### Template 2: Tangential Sources Only

Use when sources exist but none directly answers the question.

```
**Confidence:** N/A

I could not find a definitive answer to "[user question]" in the
knowledge base.

Here are the closest documents I found that may be related:
- "[Source Title 1]" -- covers [brief description of what it covers]
- "[Source Title 2]" -- covers [brief description of what it covers]

**Try searching for:**
- [alternative term 1]
- [alternative term 2]

Would you like me to search again with different keywords, or would
you like to review one of the documents above?
```

### Template 3: Contradictory Sources, No Resolution

Use when sources conflict and no precedence rule resolves the disagreement.

```
**Confidence:** Low

I found conflicting information about "[user question]" in the
knowledge base and cannot determine which is current.

- "[Source A Title]" (updated [date]) states: [claim A]
- "[Source B Title]" (updated [date]) states: [claim B]

This discrepancy may reflect a policy change or documentation error.
Recommend verifying with the document owner.

---
Sources:
[1] "Source A Title" - URL
[2] "Source B Title" - URL
```

### Alternative Search Term Generation

When suggesting alternative search terms in no-answer responses, derive terms using these strategies:

1. **Synonyms**: Replace key terms with synonyms (e.g., "refund" -> "reimbursement", "cancellation").
2. **Broader terms**: Generalize the query (e.g., "enterprise SSO setup" -> "authentication", "security settings").
3. **Related concepts**: Suggest adjacent topics that might contain the answer (e.g., "vacation policy" -> "time off", "PTO", "leave of absence").
4. **Acronym expansion**: If the query uses an acronym, suggest the expanded form and vice versa (e.g., "SLA" -> "service level agreement", "response time").

Always suggest exactly 2-3 alternatives. Fewer feels unhelpful; more overwhelms.

---

## Conflict Reconciliation Decision Tree

When sources disagree, walk through this decision tree in order:

```
1. Are the sources discussing the same scope?
   ├── NO  -> Not a true conflict. Present both with scope labels.
   │         "For [scope A], [claim A] [1]. For [scope B], [claim B] [2]."
   └── YES -> Continue to step 2.

2. Is one source more recent than the other?
   ├── YES (>30 day gap) -> Date precedence.
   │         "As of [date], [newer claim] [1]. Note: an earlier
   │          document stated [older claim] [2]."
   └── NO or <30 day gap -> Continue to step 3.

3. Is one source more specific to the question?
   ├── YES -> Specificity precedence.
   │         "Per the [specific source type] [claim] [1].
   │          A more general document notes [claim B] [2]."
   └── NO  -> Continue to step 4.

4. Is one source more authoritative (policy > notes > drafts)?
   ├── YES -> Authority precedence.
   │         "The official [doc type] states [claim] [1].
   │          An internal [doc type] notes [claim B] [2]."
   └── NO  -> Transparent disagreement. Present both. Rate Low confidence.
             "Source A states [X] [1], while Source B states [Y] [2].
              Verify with the document owner."
```

### Scope Differentiation Examples

| Apparent Conflict | Resolution |
|-------------------|------------|
| "Free tier: 5 users" vs "Free tier: 10 users" | Check if sources refer to different products or plan versions. Present both with context. |
| "Response time: 4 hours" vs "Response time: 1 hour" | Check if one refers to standard support and the other to premium. Scope-label both. |
| "Export: CSV only" vs "Export: CSV, XLSX, JSON" | Check dates -- likely a feature addition. Use date precedence if newer source adds formats. |

### Authority Hierarchy

When applying authority precedence, rank sources in this order (highest to lowest):

1. Official policy or terms-of-service pages
2. Published help center or documentation articles
3. Product changelog or release notes
4. Internal wiki pages (curated, reviewed)
5. Meeting notes or decision logs
6. Draft documents or proposals
7. Comments, threads, or inline annotations

---

## Answer Length Guidelines

### Default: Concise

Unless the user requests a detailed explanation, default to concise answers.

| Answer Type | Target Length | When to Use |
|-------------|-------------|-------------|
| Direct factual | 1-3 sentences | Single-fact questions: "What is the limit?", "When does it expire?" |
| Procedural | 3-8 sentences or numbered steps | "How do I...?" questions requiring a sequence |
| Explanatory | 4-10 sentences | "Why does...?" or "What is the difference between...?" questions |
| Comprehensive | 10-20 sentences | User explicitly asks for detail, or multi-part question with several components |

### Length Triggers

Expand beyond the default concise length when:
- The user says "explain in detail", "tell me everything about", or "give me the full picture".
- The question has 3+ distinct components that each require separate answers.
- The sources contain important caveats or exceptions that affect how the answer should be applied.

Shorten below the default when:
- The answer is a single value (a number, a date, a yes/no). Lead with the value, cite the source, done.
- The user says "quick answer", "in brief", or "TL;DR".

### Structural Guidelines

- Lead with the answer. Never bury the answer after 3 paragraphs of context.
- Use numbered steps for procedures (3+ steps).
- Use bullet points for lists of options, features, or conditions (3+ items).
- Use a single paragraph for explanatory answers unless the explanation has distinct phases or components.
- Do not repeat the user's question in the answer. They already know what they asked.

---

## Edge Cases

### Contradictory Sources from the Same Author

When two documents by the same author or team disagree, prefer the more recent one and note: "A newer document from the same author supersedes earlier guidance [1]. The earlier version stated [X] [2]."

### Stale Content with No Replacement

When the only relevant source is older than 180 days and no newer source exists:
- Use it but assign Low confidence.
- Append: "This information is from [date] and may no longer be current. No newer documentation was found on this topic."

### Partial Answers

When sources cover part of the question but not all:
- Answer what can be answered.
- Explicitly state what was not found.
- Structure: answered portion first, then "Regarding [unanswered portion], no documentation was found in the knowledge base."
- Assign Medium confidence at best for partial answers.

### Duplicate Sources

When the same content appears in multiple places (e.g., a Notion page and a Google Drive copy):
- Treat as one source for citation purposes.
- Use the more authoritative or more recently updated version as the canonical citation.
- Do not count duplicates as "multiple sources agreeing" for confidence scoring. Corroboration requires independent sources.

### Empty or Minimal Source Content

When a retrieved source has a relevant title but minimal content (fewer than 50 words):
- Do not cite it as a primary source.
- Mention it only if no better source exists: "A page titled '[Title]' exists but contains limited information."
- Do not use it to boost confidence.

### User Asks for Information Not Meant to Be Shared

When the question asks about content that appears to be restricted (contains markers like "CONFIDENTIAL", "INTERNAL ONLY", "DO NOT SHARE"):
- Answer the question (the knowledge base is assumed to be the user's own).
- Note: "This information is marked [marker] in the source document."
- Let the user decide how to handle the sensitivity.

---

## Full Answer Examples

### Example 1: High Confidence, Direct Factual

**Question**: "What is the maximum number of projects per workspace?"

```
**Confidence:** High

Each workspace supports up to 500 active projects. [1] Archived
projects do not count toward this limit. [1] If the limit is
reached, archive or delete unused projects before creating new
ones. [2]

---
Sources:
[1] "Workspace Limits and Quotas" - https://notion.so/workspace/limits-abc123
[2] "Managing Projects FAQ" - https://notion.so/workspace/faq-def456
```

**Preview**: "Each workspace supports up to 500 active projects; archived projects do not count."

### Example 2: Medium Confidence, Procedural

**Question**: "How do I set up SSO for my team?"

```
**Confidence:** Medium

SSO configuration requires a Business or Enterprise plan. [1] To
set it up:

1. Navigate to Settings > Security > Single Sign-On. [1]
2. Select the identity provider (Okta, Azure AD, or Google
   Workspace are supported). [1]
3. Enter the SAML endpoint URL and certificate from the identity
   provider. [1]
4. Enable SSO and set the enforcement policy (optional or
   required for all users). [1]

After enabling, existing users will be prompted to link their
account on next login. New users will authenticate through the
identity provider automatically. [2]

Note: a setup guide specific to each identity provider is available
in the help center, but was not found in the current knowledge
base search. [2]

---
Sources:
[1] "SSO Configuration Guide" - https://notion.so/workspace/sso-setup-ghi789
[2] "Security Settings Overview" - https://notion.so/workspace/security-jkl012

Some sources may be outdated. Verify critical details against
current documentation.
```

**Preview**: "SSO setup requires Business/Enterprise plan; configure in Settings > Security > Single Sign-On."

### Example 3: Low Confidence, Conflict Present

**Question**: "What is the data retention period after account cancellation?"

```
**Confidence:** Low

There is conflicting information about data retention after account
cancellation.

The Terms of Service page states that data is retained for 30 days
after cancellation, after which it is permanently deleted. [1]
However, a more recent support article mentions a 90-day grace
period during which data can be recovered by contacting support. [2]

The support article is newer (updated January 2026 vs. the Terms
of Service last updated August 2025), which may indicate a policy
change that has not yet been reflected in the formal terms. Verify
the current policy with the account management team before relying
on either timeframe.

---
Sources:
[1] "Terms of Service" - https://notion.so/workspace/terms-mno345
[2] "Account Cancellation FAQ" - https://notion.so/workspace/cancel-faq-pqr678
```

**Preview**: "Conflicting info: Terms of Service says 30 days, support FAQ says 90 days. Verify with account team."
