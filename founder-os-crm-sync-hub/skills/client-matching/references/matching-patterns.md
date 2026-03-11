# Matching Patterns

Reference data and pattern rules for the client-matching skill. Use these lists and rules when executing the 5-step progressive matching algorithm.

## Personal Email Domain List

Skip domain-based matching (Step 2) for any email address with one of these domains. These domains host personal accounts and do not indicate a company affiliation. Proceed directly to Step 4 (fuzzy name matching) when one of these domains is detected.

- `gmail.com`
- `googlemail.com`
- `outlook.com`
- `yahoo.com`
- `hotmail.com`
- `icloud.com`
- `aol.com`
- `protonmail.com`
- `proton.me`
- `fastmail.com`
- `me.com`
- `live.com`
- `msn.com`
- `ymail.com`
- `zoho.com`
- `mail.com`
- `gmx.com`
- `gmx.net`
- `tutanota.com`
- `tuta.io`
- `hey.com`
- `pm.me`
- `mailbox.org`
- `posteo.de`
- `disroot.org`
- `riseup.net`
- `runbox.com`
- `mailfence.com`
- `cock.li`
- `yandex.com`
- `yandex.ru`
- `qq.com`
- `163.com`
- `126.com`
- `sina.com`

Compare domains in lowercase. Match the full domain exactly -- do not partial-match (e.g., `mail.com` should not match `hotmail.com`). The extraction step already isolates the domain after the `@` symbol, so exact comparison is sufficient.

## Distribution List Patterns

Skip matching entirely for any email address whose local part (left of `@`) matches one of these patterns. Distribution addresses represent shared inboxes or automated senders, not individual contacts.

### Exact Local Part Matches

- `team`
- `info`
- `support`
- `noreply`
- `no-reply`
- `donotreply`
- `do-not-reply`
- `admin`
- `hello`
- `contact`
- `billing`
- `sales`
- `marketing`
- `help`
- `office`
- `hr`
- `careers`
- `jobs`
- `press`
- `media`
- `legal`
- `compliance`
- `security`
- `abuse`
- `postmaster`
- `webmaster`
- `feedback`
- `newsletter`
- `updates`
- `notifications`
- `alerts`
- `system`
- `mailer-daemon`
- `bounces`
- `unsubscribe`
- `subscribe`
- `ops`
- `devops`
- `engineering`
- `accounts`
- `invoices`
- `receipts`
- `orders`
- `shipping`

### Pattern-Based Matches

Also skip any local part that matches these patterns:

- Starts with `noreply-` or `no-reply-` (e.g., `noreply-orders@acme.com`)
- Starts with `auto-` (e.g., `auto-confirm@acme.com`)
- Starts with `bot-` or ends with `-bot` (e.g., `bot-notifications@acme.com`, `deploy-bot@acme.com`)
- Starts with `system-` (e.g., `system-alerts@acme.com`)
- Contains `+` character (e.g., `user+tag@acme.com`) -- note: this is an email alias, not a distribution list. Do not skip these. Instead, strip the `+` suffix and match using the base local part. `jane+newsletter@acme.com` becomes `jane@acme.com` for matching purposes.

Compare local parts in lowercase. Strip any leading or trailing whitespace before comparison.

## Domain Normalization Rules

Apply these normalization steps to every domain before using it for matching.

### Step 1: Lowercase

Convert the entire domain string to lowercase.

- `Acme.COM` becomes `acme.com`

### Step 2: Strip Common Prefixes

Remove these prefixes if they appear at the start of the domain:

- `www.` -- `www.acme.com` becomes `acme.com`
- `mail.` -- `mail.acme.com` becomes `acme.com`
- `email.` -- `email.acme.com` becomes `acme.com`

Apply prefix stripping in order. Do not strip recursively (stripping once is sufficient). Do not strip prefixes that are the entire domain (e.g., `mail.com` should remain `mail.com`, not `com`). Only strip when the remainder still contains at least one `.` character.

### Step 3: Strip Protocol Prefixes from Website Field

When comparing against the Companies DB Website property, the stored value may include a full URL. Extract the domain:

1. Remove protocol prefix: `https://`, `http://`
2. Remove trailing path: everything after the first `/` following the domain
3. Remove trailing port: `:8080` or similar
4. Apply Steps 1 and 2 above to the extracted domain

Examples:
- `https://www.acme.com/about` becomes `acme.com`
- `http://acme.com:8080` becomes `acme.com`
- `acme.com` remains `acme.com` (no protocol to strip)

### Step 4: Domain Comparison

After normalization, compare domains using exact string equality. Two domains match when their normalized forms are identical strings.

## Fuzzy Name Matching Rules

Apply these rules when executing Step 4 of the matching algorithm. Fuzzy matching is inherently lower confidence -- apply all rules conservatively to minimize false positives.

### Case-Insensitive Comparison

Convert both the search name and CRM contact names to lowercase before comparison.

- "Jane Smith" matches "jane smith" matches "JANE SMITH"

### Initial Handling

Match initials to full names and vice versa.

- "J. Smith" matches "Jane Smith" (first initial matches first name starting with J)
- "J. D. Smith" matches "Jane D. Smith" or "Jane Dorothy Smith"
- "JS" does not match "Jane Smith" -- require at least one full name component (first or last) to prevent false positives from initials alone
- When an initial matches multiple contacts (e.g., "J. Smith" matches "Jane Smith" and "John Smith"), return all candidates for user disambiguation

### Nickname and Variant Handling

Recognize common English name variants. Match any variant to any other variant in the same group.

| Formal Name | Common Variants |
|-------------|-----------------|
| Robert | Rob, Bob, Bobby, Robbie, Bert |
| William | Will, Bill, Billy, Willy, Liam |
| James | Jim, Jimmy, Jamie |
| Richard | Rich, Rick, Dick, Ricky |
| Michael | Mike, Mikey, Mick |
| Elizabeth | Liz, Beth, Lizzy, Eliza, Betty, Betsy |
| Jennifer | Jen, Jenny, Jenn |
| Katherine | Kate, Katie, Kathy, Kat, Kit, Cathy |
| Margaret | Meg, Maggie, Peggy, Marge, Margie |
| Patricia | Pat, Patty, Trish, Tricia |
| Joseph | Joe, Joey |
| Thomas | Tom, Tommy |
| Charles | Charlie, Chuck, Chas |
| Daniel | Dan, Danny |
| Matthew | Matt, Matty |
| Christopher | Chris, Topher |
| Anthony | Tony |
| Alexander | Alex, Xander |
| Benjamin | Ben, Benny |
| Nicholas | Nick, Nicky |
| David | Dave, Davey |
| Jonathan | Jon, John |
| Andrew | Andy, Drew |
| Timothy | Tim, Timmy |
| Edward | Ed, Eddie, Ted, Teddy, Ned |
| Stephen | Steve, Steven |
| Rebecca | Becca, Becky |
| Samantha | Sam, Sammy |
| Victoria | Vicky, Tori |
| Alexandra | Alex, Lexi, Sandra |

When a display name matches a variant, apply the match but keep confidence at LOW (0.4). Nickname matches are suggestive, not definitive.

### Hyphenated Name Handling

Handle hyphenated last names flexibly:

- "Garcia-Lopez" matches "Garcia-Lopez" (exact)
- "Garcia-Lopez" also matches "Garcia" or "Lopez" individually (partial match on either component)
- "Smith-Jones" matches "Smith Jones" (hyphen treated as space)
- When a partial match on one component of a hyphenated name is found, return it as a candidate but note the partial match: "Partial match: [email name] matched on '[component]' from hyphenated name '[full name]'."

### Name Order Flexibility

Match names regardless of order:

- "Smith, Jane" matches "Jane Smith"
- "Jane Smith" matches "Smith Jane"

Split on comma, space, or both. Recombine parts and compare in all orderings.

### Name Derivation from Email Local Part

When no display name is available, attempt to derive a name from the email local part:

1. Split the local part on `.`, `-`, or `_` delimiters.
2. Capitalize each resulting part.
3. Treat the parts as [FirstName, LastName] if exactly two parts exist.
4. Treat as [FirstName, MiddleName, LastName] if three parts exist.
5. If only one part exists or the parts do not resemble a name (contain digits, are fewer than 2 characters, or match common usernames like "admin", "user", "test"), abandon name derivation.

Examples:
- `jane.smith@gmail.com` derives "Jane Smith"
- `j.smith@gmail.com` derives "J Smith" (initial handling applies)
- `jane.d.smith@gmail.com` derives "Jane D Smith"
- `jsmith@gmail.com` derives nothing useful (single token, ambiguous split point)
- `cooldude99@gmail.com` derives nothing (contains digits, not a name pattern)

## Multi-Domain Company Matching

Some companies use multiple email domains. Detect and handle this pattern.

### Primary Domain

The Companies DB Website field stores the primary domain. Always check this first in Step 2.

### Secondary Domains via Contact Emails

When Step 2 fails (no Website match), search all contacts in the Contacts DB for emails with the target domain.

1. Query the Contacts DB where the Email property's domain matches the target domain.
2. If one or more contacts are found, follow their Company relation.
3. If all matching contacts link to the same company, treat it as a domain match at HIGH confidence (0.8).
4. If matching contacts link to different companies, present all candidates for disambiguation.

### Common Multi-Domain Patterns

Companies frequently use multiple domains in these scenarios:

- **Brand domains**: `brand.com` alongside `parent-corp.com`
- **Country-specific domains**: `company.com`, `company.co.uk`, `company.de`
- **Product domains**: `product-name.com` alongside `company.com`
- **Legacy domains**: Old domain still in use by some employees after a rebrand or acquisition

The matching algorithm handles these implicitly through the contact email cross-reference in Step 3. No special configuration is required -- the CRM data itself encodes the multi-domain relationship through contact records.

## Match Result Caching

During a single command invocation, cache the following to avoid redundant Notion queries:

| Cache Key | Cache Value | Invalidation |
|-----------|-------------|--------------|
| Normalized domain | Company match result (company_id, company_name, confidence) | End of command |
| Full email address | Contact match result (contact_id, contact_name, company_id) | End of command |
| Company page ID | List of associated contacts | End of command |
| Database title | Database ID | End of command |

Do not persist caches across separate command invocations. Each new command starts with empty caches. This ensures fresh data when the user modifies CRM records between commands.
