---
name: Client Matching
description: "Matches email addresses and meeting attendees to CRM contacts using progressive matching. Activates when the user needs to identify which client an email belongs to, resolve a contact, or look up a client from an email address. Uses a 5-step algorithm from exact email match to fuzzy name matching with confidence scoring."
---

## Overview

Resolve email addresses, attendee names, and domain names to CRM Pro client records in Notion. The matching algorithm uses a progressive strategy: start with exact matches (highest confidence), fall back to domain matching, then fuzzy name matching. Each match receives a confidence tier to indicate reliability.

This skill is consumed by all three plugin commands (`crm:sync-email`, `crm:sync-meeting`, `crm:context`). The commands pass in raw participant data (email addresses, display names, attendee lists) and receive structured match results with confidence scores. The skill handles only the matching logic -- it does not create or modify CRM records.

## CRM Pro Database Schema (for Matching)

Use dynamic database discovery for all lookups. Search by database title -- never hardcode database IDs.

### Companies DB

Search for a database titled "[FOS] Companies", "Founder OS HQ - Companies", "Companies", or "CRM - Companies" (in that priority order). Key properties for matching:

- **Name** (title): Company name. Use for fuzzy name matching in Step 4.
- **Website** (url): Contains the company domain (e.g., "https://acme.com"). Extract the domain portion for comparison. Some records may store just the domain without a protocol prefix.
- **Contacts** (relation): Links to the Contacts database. Follow this relation to enumerate all known contacts for a matched company.

### Contacts DB

Search for a database titled "[FOS] Contacts", "Founder OS HQ - Contacts", "Contacts", or "CRM - Contacts" (in that priority order). Key properties for matching:

- **Name** (title): Contact's full name. Use for fuzzy name matching in Step 4.
- **Email** (email): Contact's email address. Use for exact email matching in Step 3.
- **Company** (relation): Links back to the Companies database. Use to verify company association.

### Discovery Rules

1. Search for databases by title using the Notion search API.
2. Accept the FOS form ("[FOS] Companies"), HQ form ("Founder OS HQ - Companies"), short form ("Companies"), or prefixed form ("CRM - Companies"). Prefer "[FOS] Companies" first, then "Founder OS HQ - Companies", then "CRM - Companies", then "Companies".
3. If no database is found under any accepted name, report the error and stop: "Companies database not found. Ensure the Founder OS HQ workspace template or CRM Pro template is installed in your Notion workspace."
4. Cache discovered database IDs for the duration of the current command execution. Do not persist cached IDs across separate command invocations.

## 5-Step Progressive Matching Algorithm

Process each participant through these steps in order. Stop at the first step that produces a match with confidence HIGH or above. Continue through all steps only when earlier steps fail or produce MEDIUM or lower confidence.

### Step 1: Extract and Normalize Email Domain

From the email address, extract the domain portion after the `@` symbol.

1. Split the email address at `@`. Take the right-hand portion as the raw domain.
2. Convert to lowercase.
3. Strip common prefixes: remove leading `www.`, `mail.`, or `email.` if present.
4. Check the normalized domain against the personal email domain list (see `${CLAUDE_PLUGIN_ROOT}/skills/crm/client-matching/references/matching-patterns.md`). If the domain is personal, mark it as non-matchable by domain and skip directly to Step 4.
5. Check the email local part (left of `@`) against the distribution list patterns (see `${CLAUDE_PLUGIN_ROOT}/skills/crm/client-matching/references/matching-patterns.md`). If it matches a distribution list pattern, skip this participant entirely -- distribution addresses do not represent individual contacts.

### Step 2: Search Companies DB by Domain

Use the normalized domain from Step 1 to search the Companies database.

1. Query the Companies DB for records where the Website property contains the extracted domain.
2. Try variations: search with and without `www.` prefix. If the domain is `acme.com`, also search for `www.acme.com` and `https://acme.com`.
3. If exactly one company matches: set confidence to HIGH (0.8). Record the matched company name and page ID. Proceed to Step 3 for contact verification.
4. If multiple companies match the same domain: log a warning ("Multiple companies found for domain [domain]"). Select the company whose Website property most closely matches the domain. Proceed to Step 3.
5. If no company matches: proceed to Step 3 for direct email lookup.

### Step 3: Verify Against Contacts DB by Email

Search the Contacts database for a record matching the full email address.

1. Query the Contacts DB where the Email property equals the full email address (exact match, case-insensitive).
2. **Contact found, company also found in Step 2**: Verify the contact's Company relation points to the same company found in Step 2. If confirmed, set confidence to EXACT (1.0). If the contact links to a different company, prefer the contact's company link and set confidence to EXACT (1.0) -- the Contacts DB is authoritative for individual email-to-company mapping. Log the discrepancy: "Contact [name] linked to [company A] but domain matched [company B]."
3. **Contact found, no company from Step 2**: Follow the contact's Company relation to identify the company. Set confidence to EXACT (1.0).
4. **No contact found, company found in Step 2**: The domain match stands. Set confidence to MEDIUM (0.6) -- the company is known but this specific email is not in the CRM. Suggest adding the contact: "Email [address] matched to [company] by domain but is not a known contact."
5. **No contact found, no company from Step 2**: Proceed to Step 4.

### Step 4: Fuzzy Name Matching Fallback

When Steps 2 and 3 fail (personal email domain or no domain/email match), attempt name-based matching.

1. Extract the display name from the email header (`From: "Jane Smith" <jane@gmail.com>`) or meeting attendee name field.
2. If no display name is available, attempt to derive a name from the email local part: split on `.`, `-`, `_` delimiters. Capitalize each part. Skip this derivation if the local part appears to be a username rather than a name (e.g., "cooldude99").
3. Search the Contacts DB for records where the Name property partially matches the extracted name. Use case-insensitive comparison.
4. Apply fuzzy matching rules from `${CLAUDE_PLUGIN_ROOT}/skills/crm/client-matching/references/matching-patterns.md`: handle initials, nickname variants, and hyphenated names.
5. If exactly one contact matches: follow the Company relation to identify the company. Set confidence to LOW (0.4).
6. If multiple contacts match: present all candidates to the user for disambiguation. Do not auto-select. Format: "Multiple contacts match '[name]': [Contact A] at [Company A], [Contact B] at [Company B]. Which client does this belong to?"
7. If no contacts match: search the Companies DB by partial name match. If a company matches, set confidence to LOW (0.4). If nothing matches, proceed to Step 5.

### Step 5: No Match Handling

When all previous steps fail, return an unmatched result.

1. Set confidence to NONE (0.0).
2. Populate the match output with all extracted information: email address, normalized domain, display name, derived name parts.
3. In interactive mode (single email/meeting sync): prompt the user: "Could not match [email/name] to a CRM client. Select a client from the CRM, create a new contact, or skip?"
4. In batch mode (multiple items being processed): collect all unmatched participants into a list. Present the full list at the end of batch processing for bulk resolution. Format: "N unmatched participants found. Review and assign: [list with email, name, and domain for each]."
5. Never silently discard unmatched participants. Always surface them to the user.

## Confidence Tiers

| Tier | Score | Meaning | Match Method |
|------|-------|---------|--------------|
| EXACT | 1.0 | Full email address verified in Contacts DB | Email → Contact → Company |
| HIGH | 0.8 | Domain matched to a Company in the CRM | Domain → Company, contact not verified |
| MEDIUM | 0.6 | Domain matched to Company but contact not in CRM | Domain → Company, unknown contact |
| LOW | 0.4 | Fuzzy name match only, no email or domain confirmation | Display name → Contact or Company |
| NONE | 0.0 | No match found through any method | Unresolved |

When presenting match results to the user or writing them to CRM records, always include the confidence tier and match method. Downstream commands use the confidence score to decide how aggressively to act: EXACT and HIGH matches proceed automatically, MEDIUM matches proceed with a note, LOW matches require user confirmation.

## Match Output Schema

Return one match result object per participant:

```
{
  client_name: string,            // Company name from CRM, or null if unmatched
  company_id: string,             // Notion page ID for the Company, or null
  contact_name: string | null,    // Contact name if resolved, null otherwise
  contact_id: string | null,      // Notion page ID for the Contact, or null
  match_confidence: "exact" | "high" | "medium" | "low" | "none",
  confidence_score: 0.0-1.0,      // Numeric confidence
  match_method: string,           // Human-readable description of how the match was made
  source_email: string | null,    // Original email address that was matched
  source_name: string | null      // Original display name or attendee name
}
```

When matching multiple participants (e.g., all attendees of a meeting or all recipients of an email), return an array of match results. Group results by company when presenting to the user: show all matched contacts under their parent company.

## Batch Matching Optimization

When processing multiple participants in a single command invocation:

1. Deduplicate email addresses before matching. Process each unique email once.
2. Build a domain-to-company cache during the batch. After the first domain lookup succeeds, reuse the cached result for subsequent emails with the same domain. This avoids redundant Notion queries.
3. Build a company-to-contacts cache. After fetching a company's contact list, cache it for the duration of the batch.
4. Process participants in domain-grouped order: group all emails by domain, process each domain group together. This maximizes cache hits.
5. Report batch summary at completion: "Matched X/Y participants. Z exact, W high, V medium, U low, T unmatched."

## Multiple Contacts at Same Company

When a domain matches a company but multiple contacts exist at that company:

1. If the email address exactly matches one contact: return that contact (EXACT confidence).
2. If the email does not match any contact but the domain matches the company: return the company match with no specific contact (MEDIUM confidence).
3. When presenting to the user, list all known contacts at the company for reference: "[email] matched to [Company] (domain match). Known contacts: [Contact A], [Contact B], [Contact C]."

## Email Alias and Multi-Domain Companies

Some companies operate under multiple domains (e.g., `company.com` and `company.io`, or `brand.com` and `parent-corp.com`).

1. The Companies DB Website property stores the primary domain. Check this first.
2. If no primary domain match: search all contact emails in the Contacts DB for the domain. If any contact's email uses the target domain and links to a company, treat that company as a match at HIGH confidence.
3. This cross-reference catches alias domains that are not recorded in the Company's Website field but appear in individual contact emails.

## Edge Cases

### Forwarded Emails

When processing a forwarded email, identify the original sender. Look for "Forwarded message" or "---------- Forwarded message ----------" markers. Extract the original `From:` address and match against that address, not the forwarder's address.

### CC and BCC Participants

Match CC recipients the same as primary recipients. BCC recipients are not visible in received emails -- do not attempt to match them. When syncing sent emails, the user's own email address appears as the sender -- skip matching the user's own address.

### Calendar Events Without Email Addresses

Some calendar events list attendees by name only (no email address). In this case, skip directly to Step 4 (fuzzy name matching). Set a maximum confidence of LOW (0.4) for name-only matches from calendar events.

### Self-Match Prevention

Skip matching the user's own email address(es). Detect the user's address from the Gmail account or from Notion CRM "My Company" records. The user's email should never appear as a matched client.

### Empty or Malformed Email Addresses

Skip any participant with an empty email field, an email missing the `@` symbol, or an obviously invalid format. Log: "Skipped malformed email: [value]." Do not count these as unmatched -- they are invalid input.

## Additional Resources

For detailed personal email domain lists, distribution list patterns, domain normalization rules, and fuzzy name matching specifications, consult `${CLAUDE_PLUGIN_ROOT}/skills/crm/client-matching/references/matching-patterns.md`.
