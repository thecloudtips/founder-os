# Integration Test Plan: #24 LinkedIn Post Generator

**Plugin**: `founder-os-linkedin-post-generator/`
**Pattern**: None (standalone, no Agent Teams)
**MCP**: Filesystem (required), Notion (optional)
**Commands**: `/linkedin:post`, `/linkedin:variations`, `/linkedin:from-doc`
**Skills**: linkedin-writing, hook-creation, founder-voice
**Template**: `templates/linkedin-post-template.md`

---

## 1. Command: /linkedin:post

### T01 -- Basic Post Generation (Topic Only, All Defaults)

| Field | Value |
|-------|-------|
| **ID** | T01 |
| **Description** | Generate a LinkedIn post with only a topic provided, all other parameters at defaults. |
| **Steps** | 1. Run `/linkedin:post "Why most startups fail at hiring"`. 2. Observe output in chat. |
| **Expected Result** | A complete LinkedIn post is generated using auto-selected framework, default audience (founder), default length (medium 500-1500 chars), no emojis, no file output. Post includes hook, body, CTA, and 3-5 hashtags. |
| **Pass Criteria** | Post is between 500-1500 characters. Contains a clear hook opening line, structured body, CTA, and hashtag block. Framework was auto-selected based on topic. Founder voice is present (professional-but-conversational). |

### T02 -- Each Framework Explicitly (7 Tests)

| Field | Value |
|-------|-------|
| **ID** | T02a-T02g |
| **Description** | Generate a post for each of the 7 frameworks to verify framework-specific structure. |
| **Steps** | Run each of the following: 1. `/linkedin:post "hiring mistakes" --framework=story` 2. `/linkedin:post "productivity tools" --framework=listicle` 3. `/linkedin:post "remote work is overrated" --framework=contrarian` 4. `/linkedin:post "setting up CI/CD" --framework=howto` 5. `/linkedin:post "my first failed startup" --framework=lesson` 6. `/linkedin:post "AI in healthcare 2026" --framework=insight` 7. `/linkedin:post "what's your biggest regret?" --framework=question` |
| **Expected Result** | Each post follows its framework-specific structure: (a) Story: narrative arc with setup/conflict/resolution/takeaway. (b) Listicle: numbered items with brief explanations. (c) Contrarian: bold opening claim, evidence against conventional wisdom, reframe. (d) How-To: step-by-step actionable instructions. (e) Lesson: personal experience, mistake/failure, lesson learned. (f) Insight: data or trend, analysis, implication for the reader. (g) Question: provocative question hook, context framing, invitation to comment. |
| **Pass Criteria** | Each post clearly maps to its framework structure. No two frameworks produce structurally identical output. All posts include hook, body, CTA, and hashtags. |

### T03 -- Each Audience Segment (4 Tests)

| Field | Value |
|-------|-------|
| **ID** | T03a-T03d |
| **Description** | Generate posts for the same topic across all 4 audience segments. |
| **Steps** | Using topic "scaling a SaaS business": 1. `/linkedin:post "scaling a SaaS business" --audience=founder` 2. `/linkedin:post "scaling a SaaS business" --audience=technical` 3. `/linkedin:post "scaling a SaaS business" --audience=marketer` 4. `/linkedin:post "scaling a SaaS business" --audience=cxo` |
| **Expected Result** | (a) Founder: conversational, practical, uses "we/I" language, references bootstrapping/fundraising. (b) Technical: includes technical specifics, architecture references, data-driven claims. (c) Marketer: emphasizes growth metrics, positioning, customer acquisition language. (d) CXO: formal but human, strategic framing, P&L/board-level language. |
| **Pass Criteria** | Vocabulary and tone shift noticeably between segments. CTA style matches audience (founder=action, technical=discussion, marketer=share, cxo=connect). Same core message but different framing per segment. |

### T04 -- Each Length Mode (3 Tests)

| Field | Value |
|-------|-------|
| **ID** | T04a-T04c |
| **Description** | Verify the 3 length modes produce posts within their character ranges. |
| **Steps** | Using topic "the future of remote work": 1. `/linkedin:post "the future of remote work" --length=short` 2. `/linkedin:post "the future of remote work" --length=medium` 3. `/linkedin:post "the future of remote work" --length=long` |
| **Expected Result** | (a) Short: under 500 characters total (excluding hashtags). (b) Medium: 500-1500 characters total (excluding hashtags). (c) Long: 1500-3000 characters total (excluding hashtags). |
| **Pass Criteria** | Each post falls within its specified character range. Short posts are punchy and concise. Long posts have more depth, examples, or narrative. All three still contain hook, body, CTA, and hashtags. |

### T05 -- Emoji Toggle

| Field | Value |
|-------|-------|
| **ID** | T05 |
| **Description** | Verify the `--emojis` flag adds emojis and default omits them. |
| **Steps** | 1. Run `/linkedin:post "team building tips"` (no emoji flag). 2. Run `/linkedin:post "team building tips" --emojis`. |
| **Expected Result** | (1) Output contains no emojis anywhere in the post body, hook, or CTA. (2) Output contains emojis used as bullet markers, section dividers, or emphasis. Emojis are tasteful and LinkedIn-appropriate (not excessive). |
| **Pass Criteria** | Default output has zero emoji characters. `--emojis` output has at least 2 but no more than 10 emojis. Emojis do not appear in hashtags. |

### T06 -- Custom Output Path

| Field | Value |
|-------|-------|
| **ID** | T06 |
| **Description** | Verify file output with `--output` flag writes to the specified path with YAML frontmatter. |
| **Steps** | 1. Run `/linkedin:post "AI automation" --output=linkedin-posts/ai-automation.md`. 2. Read the output file. |
| **Expected Result** | File is created at the specified path (relative to `${CLAUDE_PLUGIN_ROOT}`). File contains YAML frontmatter with fields: topic, framework, audience, length, generated_at, hashtags. Post content follows after the frontmatter block. Intermediate directories are created if they do not exist. |
| **Pass Criteria** | File exists at specified path. YAML frontmatter is valid and contains all expected fields. Post content matches what was shown in chat. Directory was created automatically. |

### T07 -- Auto-Framework Selection Logic

| Field | Value |
|-------|-------|
| **ID** | T07 |
| **Description** | Verify the plugin auto-selects an appropriate framework when none is specified. |
| **Steps** | Run the following without `--framework`: 1. `/linkedin:post "3 tools every founder needs"` (should select listicle). 2. `/linkedin:post "I almost shut down my company last year"` (should select story or lesson). 3. `/linkedin:post "Everyone says you need a co-founder. I disagree."` (should select contrarian). 4. `/linkedin:post "How to set up automated invoicing"` (should select howto). |
| **Expected Result** | The plugin selects a framework that matches the topic's natural structure. Listicle-like topics get listicle. Narrative topics get story or lesson. Opinionated topics get contrarian. Instructional topics get howto. The selected framework is reported in the output metadata. |
| **Pass Criteria** | At least 3 out of 4 topics map to the expected framework. The selected framework name is visible in the output or frontmatter. Post structure matches the selected framework. |

### T08 -- No Topic Provided (Should Prompt)

| Field | Value |
|-------|-------|
| **ID** | T08 |
| **Description** | Verify the plugin prompts the user when no topic is given. |
| **Steps** | 1. Run `/linkedin:post` with no arguments. |
| **Expected Result** | The plugin asks the user to provide a topic rather than generating a post about nothing. It does not error or produce an empty/generic post. |
| **Pass Criteria** | User receives a clear prompt asking for a topic. No post is generated until a topic is provided. No unhandled error occurs. |

### T09 -- Character Limit Enforcement at 3000

| Field | Value |
|-------|-------|
| **ID** | T09 |
| **Description** | Verify the hard 3000-character limit is enforced even with `--length=long` and a verbose topic. |
| **Steps** | 1. Run `/linkedin:post "comprehensive guide to building and scaling a SaaS startup from zero to $10M ARR including hiring, product-market fit, fundraising, go-to-market strategy, and operational excellence" --length=long`. 2. Count total characters in the generated post body (excluding hashtag block). |
| **Expected Result** | The generated post does not exceed 3000 characters. Content is complete and coherent despite the constraint. The post does not feel abruptly truncated. |
| **Pass Criteria** | Character count of the post body (excluding hashtags) is at or below 3000. Post reads as a complete, well-structured piece. No mid-sentence cutoffs. |

---

## 2. Command: /linkedin:variations

### T10 -- Variations from Prior /linkedin:post Output

| Field | Value |
|-------|-------|
| **ID** | T10 |
| **Description** | Generate variations using the output of a prior `/linkedin:post` command. |
| **Steps** | 1. Run `/linkedin:post "AI automation for small business"`. 2. Run `/linkedin:variations` (should use the prior output as input). |
| **Expected Result** | 3 variations are generated (default count). Each variation presents the same core topic with a different framework and hook style. All variations maintain the same audience segment from the original post. |
| **Pass Criteria** | 3 distinct variations produced. Each uses a different framework than the others. Core topic remains consistent. Audience tone matches the original. |

### T11 -- Variations from Pasted Text

| Field | Value |
|-------|-------|
| **ID** | T11 |
| **Description** | Generate variations from user-pasted text that is not a prior post. |
| **Steps** | 1. Run `/linkedin:variations "We just hit $1M ARR after 18 months of grinding. Here's what nobody tells you about the journey from zero to seven figures."`. |
| **Expected Result** | Variations are generated that rework the pasted text into different frameworks while preserving the core message (milestone achievement, lessons learned). |
| **Pass Criteria** | Each variation retains the key facts ($1M ARR, 18 months). Different frameworks are applied. Posts are complete and publishable. |

### T12 -- Variations from Topic Only

| Field | Value |
|-------|-------|
| **ID** | T12 |
| **Description** | Generate variations from just a topic string (no prior draft). |
| **Steps** | 1. Run `/linkedin:variations "founder burnout"`. |
| **Expected Result** | Multiple complete LinkedIn posts are generated on the topic, each using a different framework. Since there is no draft to vary, each post is independently generated. |
| **Pass Criteria** | All variations are on-topic. Each uses a distinct framework. Posts are full-length and publishable (not outlines or fragments). |

### T13 -- Custom Count (1, 3, 5)

| Field | Value |
|-------|-------|
| **ID** | T13a-T13c |
| **Description** | Verify the `--count` flag controls the number of variations. |
| **Steps** | 1. `/linkedin:variations "startup funding" --count=1` 2. `/linkedin:variations "startup funding" --count=3` 3. `/linkedin:variations "startup funding" --count=5` |
| **Expected Result** | (a) Exactly 1 variation. (b) Exactly 3 variations. (c) Exactly 5 variations. |
| **Pass Criteria** | Output count matches the `--count` value exactly. Each variation within a set uses a different framework. All variations are complete posts. |

### T14 -- Audience Segment Inheritance

| Field | Value |
|-------|-------|
| **ID** | T14 |
| **Description** | Verify variations inherit or accept the `--audience` flag. |
| **Steps** | 1. Run `/linkedin:post "cloud migration" --audience=technical`. 2. Run `/linkedin:variations` (should inherit technical audience). 3. Run `/linkedin:variations "cloud migration" --audience=cxo` (should override to CXO). |
| **Expected Result** | (2) Variations use technical vocabulary and tone matching the original post's audience. (3) Variations use CXO-appropriate strategic language, overriding the original's technical tone. |
| **Pass Criteria** | Inherited audience produces technically-toned variations. Explicit `--audience` override produces CXO-toned variations. Both sets are internally consistent in tone. |

### T15 -- No Input Provided (Should Prompt)

| Field | Value |
|-------|-------|
| **ID** | T15 |
| **Description** | Verify the plugin prompts the user when no input is given and there is no prior post context. |
| **Steps** | 1. Start a fresh session (no prior `/linkedin:post` output). 2. Run `/linkedin:variations` with no arguments. |
| **Expected Result** | The plugin asks the user to provide a draft, topic, or text to create variations from. It does not generate variations from nothing. |
| **Pass Criteria** | User receives a clear prompt for input. No empty or nonsensical variations are generated. No unhandled error. |

### T16 -- Each Variation Uses Different Framework and Hook

| Field | Value |
|-------|-------|
| **ID** | T16 |
| **Description** | Verify that variations are structurally distinct, not just rewording the same framework. |
| **Steps** | 1. Run `/linkedin:variations "building in public" --count=5`. 2. Analyze the framework and hook formula used in each variation. |
| **Expected Result** | Each of the 5 variations uses a different framework (e.g., story, listicle, contrarian, howto, lesson). Each variation opens with a different hook formula (e.g., stat-led, question, story, contrarian, bold claim). |
| **Pass Criteria** | No two variations share the same framework. No two variations share the same hook formula type. Each variation has a visibly different structural pattern. |

---

## 3. Command: /linkedin:from-doc

### T17 -- Markdown File Input

| Field | Value |
|-------|-------|
| **ID** | T17 |
| **Description** | Generate a LinkedIn post from a `.md` file. |
| **Steps** | 1. Create a markdown file at `test-docs/sample-blog.md` with ~500 words of blog content about AI productivity. 2. Run `/linkedin:from-doc test-docs/sample-blog.md`. |
| **Expected Result** | A LinkedIn post is generated that distills the key points from the blog post. The post captures the main argument and 2-3 supporting points. Framework is auto-selected based on document type (blog = likely story or insight). |
| **Pass Criteria** | Post content directly references or paraphrases key points from the source document. Post is within default medium length range (500-1500 chars). Source file is read successfully. Post is a standalone piece (not a summary with "read more" links). |

### T18 -- Text File Input

| Field | Value |
|-------|-------|
| **ID** | T18 |
| **Description** | Generate a LinkedIn post from a `.txt` file. |
| **Steps** | 1. Create a plain text file at `test-docs/meeting-notes.txt` with meeting notes about a product launch. 2. Run `/linkedin:from-doc test-docs/meeting-notes.txt`. |
| **Expected Result** | A LinkedIn post is generated from the meeting notes, focusing on the most LinkedIn-relevant content (launch announcement, lessons, insights). Mundane meeting details (scheduling, logistics) are filtered out. |
| **Pass Criteria** | Post extracts key points from the text file. Meeting logistics are excluded. Post is publication-ready. File is read without error. |

### T19 -- PDF File Input

| Field | Value |
|-------|-------|
| **ID** | T19 |
| **Description** | Generate a LinkedIn post from a `.pdf` file. |
| **Steps** | 1. Place a PDF file (e.g., a one-page case study) at `test-docs/case-study.pdf`. 2. Run `/linkedin:from-doc test-docs/case-study.pdf`. |
| **Expected Result** | The plugin reads the PDF content and generates a LinkedIn post. If the PDF cannot be parsed, a clear error message is shown (not a crash). |
| **Pass Criteria** | If PDF is readable: post reflects the document's content. If PDF parsing fails: user gets a clear error message suggesting alternative formats (.md, .txt). No unhandled exception. |

### T20 -- Pasted Text Input

| Field | Value |
|-------|-------|
| **ID** | T20 |
| **Description** | Generate a LinkedIn post from text pasted directly into the command. |
| **Steps** | 1. Run `/linkedin:from-doc "Our Q4 results exceeded expectations. Revenue grew 45% YoY while keeping burn rate flat. The key was focusing on expansion revenue from existing customers rather than chasing new logos."`. |
| **Expected Result** | A LinkedIn post is generated from the pasted text, expanding it into a complete structured post with hook, body, CTA, and hashtags. |
| **Pass Criteria** | Post incorporates the key data points (45% YoY, burn rate, expansion revenue). Post is longer and more structured than the input text. Framework is auto-selected. |

### T21 -- File Not Found Error

| Field | Value |
|-------|-------|
| **ID** | T21 |
| **Description** | Verify graceful error handling when a file path does not exist. |
| **Steps** | 1. Run `/linkedin:from-doc nonexistent/path/document.md`. |
| **Expected Result** | The plugin returns a clear, user-friendly error message indicating the file was not found. It suggests checking the path or using pasted text instead. |
| **Pass Criteria** | Error message names the file path that was not found. No stack trace or internal error exposed. Suggestion to use alternative input method is provided. |

### T22 -- Auto-Framework Selection from Document Type

| Field | Value |
|-------|-------|
| **ID** | T22 |
| **Description** | Verify the plugin selects an appropriate framework based on the document content type. |
| **Steps** | 1. Create a how-to guide document and run `/linkedin:from-doc test-docs/howto-guide.md`. 2. Create a case study document and run `/linkedin:from-doc test-docs/case-study.md`. 3. Create a data report document and run `/linkedin:from-doc test-docs/data-report.md`. |
| **Expected Result** | (1) How-to guide content selects howto or listicle framework. (2) Case study content selects story or lesson framework. (3) Data report content selects insight framework. |
| **Pass Criteria** | At least 2 out of 3 documents map to a contextually appropriate framework. The selected framework is visible in output metadata. |

### T23 -- Key Point Extraction Quality

| Field | Value |
|-------|-------|
| **ID** | T23 |
| **Description** | Verify the plugin extracts the most important points from a longer document, not just the beginning. |
| **Steps** | 1. Create a 1500+ word document with 5 distinct sections, where the most important insight is in section 4. 2. Run `/linkedin:from-doc test-docs/long-article.md`. |
| **Expected Result** | The generated post includes or references the key insight from section 4, not just content from the first paragraph. The post represents the document's main argument, not a truncated summary. |
| **Pass Criteria** | Post references content from beyond the first 200 words of the document. The most important insight from the source is present in the post. Post is a cohesive piece, not a sequential summary of sections. |

---

## 4. Cross-Cutting

### T24 -- Notion Integration (Consolidated DB Discovery)

| Field | Value |
|-------|-------|
| **ID** | T24 |
| **Description** | Verify posts are logged to the consolidated "[FOS] Content" database with correct Type. |
| **Steps** | 1. Ensure "[FOS] Content" DB exists in Notion. 2. Run `/linkedin:post "founder productivity"`. 3. Check Notion for the logged post. 4. Run `/linkedin:post "team building"`. 5. Verify second post was added to the same DB. |
| **Expected Result** | (2) Post is logged to "[FOS] Content" with Type="LinkedIn Post". Title="founder productivity". Content, Framework, Audience, Length, Hashtags, Style Notes, Output File, Generated At all populated. (4) Second post is appended to the same DB as a separate row. No new DB created. |
| **Pass Criteria** | Posts appear in "[FOS] Content" with Type="LinkedIn Post". No "LinkedIn Post Generator - Posts" DB created. Both posts appear as separate rows. Idempotent: re-running the same topic+framework+day updates existing row. |

### T24a -- Notion Integration (Legacy DB Fallback)

| Field | Value |
|-------|-------|
| **ID** | T24a |
| **Description** | Verify posts fall back to legacy "LinkedIn Post Generator - Posts" DB when consolidated DB is not found. |
| **Steps** | 1. Ensure "[FOS] Content" and "Founder OS HQ - Content" do NOT exist. Ensure "LinkedIn Post Generator - Posts" exists. 2. Run `/linkedin:post "legacy test"`. 3. Check Notion. |
| **Expected Result** | Post is logged to "LinkedIn Post Generator - Posts" (legacy fallback). No new database is created. |
| **Pass Criteria** | Post appears in legacy DB. No new DB created. No errors. |

### T25 -- Notion Graceful Degradation (Notion Unavailable)

| Field | Value |
|-------|-------|
| **ID** | T25 |
| **Description** | Verify the plugin works fully when Notion MCP is unavailable. |
| **Steps** | 1. Disconnect or disable the Notion MCP server. 2. Run `/linkedin:post "AI trends 2026"`. 3. Run `/linkedin:variations "AI trends"`. 4. Run `/linkedin:from-doc test-docs/sample-blog.md`. |
| **Expected Result** | All three commands produce complete output in chat. No error messages about Notion. Posts are not logged to Notion (silently skipped). No database is created. File output via `--output` still works. |
| **Pass Criteria** | All commands complete without error. Chat output is identical in quality to when Notion is available. No "Notion unavailable" warning pollutes the post output (may appear in a separate status line). No database creation attempted. |

### T26 -- File Output (Directory Creation, YAML Frontmatter)

| Field | Value |
|-------|-------|
| **ID** | T26 |
| **Description** | Verify file output creates directories, writes YAML frontmatter, and stores the post correctly. |
| **Steps** | 1. Run `/linkedin:post "automation tips" --output=linkedin-posts/2026/march/automation-tips.md`. 2. Read the output file. 3. Verify directory structure was created. |
| **Expected Result** | File exists at the specified nested path. Directories `linkedin-posts/2026/march/` were created automatically. File begins with YAML frontmatter block (delimited by `---`) containing: topic, framework, audience, length, generated_at, hashtags. Post content follows the frontmatter. |
| **Pass Criteria** | File exists and is readable. YAML frontmatter is valid (parseable). All metadata fields are present and correctly populated. Post content matches chat output. Nested directories were created. |

### T27 -- Hashtag Generation (3-5 Tags, CamelCase, Broad+Niche Mix)

| Field | Value |
|-------|-------|
| **ID** | T27 |
| **Description** | Verify hashtag generation follows the specified rules across multiple posts. |
| **Steps** | 1. Run `/linkedin:post "machine learning in fintech"`. 2. Run `/linkedin:post "hiring your first employee"`. 3. Run `/linkedin:post "Notion productivity setup"`. 4. Examine the hashtag block of each post. |
| **Expected Result** | Each post has 3-5 hashtags. Hashtags use #CamelCase format (e.g., #MachineLearning, not #machinelearning or #MACHINELEARNING). Mix includes both broad tags (e.g., #AI, #Startups, #Leadership) and niche tags specific to the topic (e.g., #FinTech, #HiringTips, #NotionSetup). |
| **Pass Criteria** | Every post has between 3 and 5 hashtags (inclusive). All hashtags use CamelCase. At least 1 broad tag and 1 niche tag per post. No duplicate hashtags within a single post. Hashtags are relevant to the topic. |

### T28 -- Founder Voice Consistency Across Commands

| Field | Value |
|-------|-------|
| **ID** | T28 |
| **Description** | Verify the founder voice skill produces consistent tone across all 3 commands. |
| **Steps** | 1. Run `/linkedin:post "delegating as a founder"`. 2. Run `/linkedin:variations "delegating as a founder"`. 3. Run `/linkedin:from-doc` with a document about delegation. 4. Compare the voice and tone across all outputs. |
| **Expected Result** | All outputs use professional-but-conversational tone. Compressed sentence rhythm is present. Opinion injection appears naturally. LinkedIn-specific anti-patterns are absent (no "thought leader" jargon, no "I'm humbled", no engagement bait like "agree?"). |
| **Pass Criteria** | Tone is consistent across all 3 commands. No output reads as corporate or robotic. No LinkedIn anti-patterns detected: no "agree?" endings, no "I'm excited to announce", no "thoughts?" as a CTA, no excessive self-congratulation. All outputs sound like a real founder writing authentically. |

### T29 -- Quality Checklist Enforcement

| Field | Value |
|-------|-------|
| **ID** | T29 |
| **Description** | Verify the linkedin-writing skill's quality checklist is enforced on all generated posts. |
| **Steps** | 1. Generate 5 posts across different frameworks and audiences. 2. Evaluate each against the quality checklist criteria. |
| **Expected Result** | Every post passes: (a) Has a hook in the first line. (b) Uses line breaks for readability (no wall of text). (c) Contains a clear CTA. (d) Has 3-5 relevant hashtags. (e) Is within the specified length range. (f) Does not start with "I" (LinkedIn anti-pattern). (g) Does not use more than 1 question mark in the first 2 lines (except question-led framework). |
| **Pass Criteria** | All 5 posts pass all checklist items. Any post that fails a checklist item indicates a skill enforcement gap. |

### T30 -- Skill Loading (All 3 Skills + Template Loaded Before Generation)

| Field | Value |
|-------|-------|
| **ID** | T30 |
| **Description** | Verify that all 3 skills and the template are loaded and referenced during post generation. |
| **Steps** | 1. Run `/linkedin:post "building a personal brand" --framework=story --audience=founder --length=long`. 2. Observe the generation process for evidence of skill loading. |
| **Expected Result** | The generation process references: (a) linkedin-writing skill (framework structure, length rules, quality checklist). (b) hook-creation skill (opening line formula). (c) founder-voice skill (tone and style rules). (d) linkedin-post-template.md (Mustache-style template structure). All 3 skills contribute to the final output. |
| **Pass Criteria** | Post structure matches the story framework from linkedin-writing. Opening line follows a hook formula from hook-creation. Tone matches founder-voice patterns. Output format aligns with the template structure. Removing any one skill would produce a noticeably different (worse) result. |

---

## Test Execution Notes

- **Environment**: All tests assume Filesystem MCP is connected and functional.
- **Notion tests** (T24, T25): Run T25 first (degradation) then T24 (integration) to avoid DB pre-existence issues, or manually clean up between runs.
- **File output tests** (T06, T26): Clean up generated files and directories after testing.
- **Character counting** (T04, T09): Count post body characters only, excluding the hashtag block and any YAML frontmatter.
- **Framework detection** (T07, T22): Allow for reasonable framework selection -- the plugin may choose a valid alternative framework. Flag only clearly wrong selections (e.g., howto framework for a personal story topic).
- **Variations command** (T10-T16): The `/linkedin:variations` command is ephemeral (no Notion logging, no file output) by design, matching the P19 `/slack:catch-up` pattern.
