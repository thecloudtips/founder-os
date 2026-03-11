# Clause Patterns Reference

Detailed extraction patterns for each of the 7 key term categories in the contract-analysis skill. For each category: what to look for, common clause language examples, extraction rules, red flags, and contract type variations.

---

## 1. Payment

### What to Look For

Scan for these section headings: "Payment", "Compensation", "Fees", "Pricing", "Payment Terms", "Rate", "Cost", "Billing".

Keywords and phrases within the section:
- Amount indicators: dollar signs ($), currency codes (USD, EUR, GBP, CAD, AUD), "per hour", "per month", "annual", "flat fee", "lump sum", "retainer"
- Schedule indicators: "net 30", "net 60", "net 15", "due upon receipt", "upon completion", "milestone-based", "monthly", "quarterly", "bi-weekly", "advance payment"
- Penalty indicators: "late payment", "interest rate", "penalty", "past due", "overdue", "finance charge"
- Expense indicators: "reimbursable expenses", "out-of-pocket", "travel expenses", "pre-approved", "at cost", "markup"

### Common Clause Language Examples

**Fixed-fee payment with milestones:**
> "Client shall pay Contractor a total fixed fee of $25,000 for the Services, payable in three installments: (i) $8,333 upon execution of this Agreement; (ii) $8,333 upon delivery of the first draft; and (iii) $8,334 upon final acceptance of all Deliverables."

**Hourly rate with monthly invoicing:**
> "Consultant shall be compensated at a rate of $150 per hour for all Services rendered. Consultant shall submit invoices on the first business day of each month for Services performed during the preceding month. Client shall pay each invoice within thirty (30) days of receipt."

**Retainer with overage billing:**
> "Client agrees to pay a monthly retainer of $5,000, which includes up to 40 hours of Services per month. Hours in excess of 40 per month shall be billed at $150 per hour and invoiced separately."

### Extraction Rules

- Parse monetary amounts by removing currency symbols and commas, converting to a number. Preserve the currency code.
- Convert payment schedule descriptions to a normalized form: "net 30" = 30 days, "upon receipt" = 0 days, "upon completion" = on delivery.
- For milestone-based payments, extract each milestone and its associated amount as a list.
- For hourly rates, extract the rate and any caps (monthly hour maximums, project not-to-exceed amounts).
- Late payment interest: extract as an annual percentage rate. "1.5% per month" = 18% per annum.
- When payment terms span multiple clauses (e.g., rate in one section, schedule in another), consolidate into a single extraction.

### Red Flags

- No specified payment amount or rate (vague "to be determined" language without a mechanism for determination).
- Payment terms exceeding net 60 for freelancers or small contractors.
- Late payment interest rate above 18% per annum (may exceed usury limits in some jurisdictions).
- All payment upon completion with no milestones (high risk for the service provider).
- No expense reimbursement clause when the project requires travel or third-party purchases.
- "Pay when paid" clauses where client's payment obligation depends on client receiving payment from a third party.

### Contract Type Variations

- **Service Agreements**: Typically feature monthly invoicing, net 30 terms, hourly or project-based pricing with detailed rate cards.
- **Freelance Contracts**: Often milestone-based or fixed-fee. May include deposit requirements (25-50% upfront). Shorter payment cycles (net 15 or net 30).
- **Agency Agreements**: Retainer-based with overage billing. May include media pass-through costs billed separately. Commission structures on performance metrics.
- **NDAs**: Rarely contain payment terms. If payment is present, it may indicate the NDA is part of a broader engagement.
- **Employment Contracts**: Salary (annual or monthly), bonus structures, equity/options, benefits packages rather than invoicing terms.

---

## 2. Duration / Renewal

### What to Look For

Scan for these section headings: "Term", "Term and Termination", "Duration", "Effective Date", "Commencement", "Renewal", "Expiration".

Keywords and phrases within the section:
- Start indicators: "effective date", "commencement date", "effective as of", "beginning on"
- End indicators: "expiration date", "initial term of", "for a period of", "until"
- Renewal indicators: "automatically renew", "auto-renew", "successive terms", "renewal period", "evergreen", "perpetual"
- Notice indicators: "written notice", "days prior to", "notice of non-renewal", "opt out"
- Duration units: "months", "years", "days", "weeks", "calendar days", "business days"

### Common Clause Language Examples

**Fixed term with auto-renewal:**
> "This Agreement shall commence on the Effective Date and shall continue for an initial term of twelve (12) months (the 'Initial Term'). Thereafter, this Agreement shall automatically renew for successive twelve (12) month periods (each a 'Renewal Term') unless either party provides written notice of non-renewal at least sixty (60) days prior to the end of the then-current term."

**Perpetual until terminated:**
> "This Agreement shall be effective as of the date first written above and shall continue in perpetuity until terminated by either party in accordance with Section 8 (Termination)."

**Project-based duration:**
> "This Agreement shall commence on January 15, 2026 and shall expire upon completion of the Deliverables described in Exhibit A, or on June 30, 2026, whichever occurs first (the 'Term')."

### Extraction Rules

- Parse dates into ISO 8601 format (YYYY-MM-DD). Handle "the date first written above", "the Effective Date", and similar references by noting "See signature block" or extracting from the preamble.
- Calculate total initial term in months. "Twelve (12) months" = 12 months. "One (1) year" = 12 months. "365 days" = 12 months.
- For auto-renewal, extract both the renewal period length and the notice period required to prevent renewal.
- Distinguish between "perpetual" (no end date, continues indefinitely) and "at-will" (either party can terminate at any time with or without notice).
- When the effective date is "upon execution" or "upon signing", note this and flag that the actual date depends on the signature date.

### Red Flags

- Auto-renewal with no opt-out mechanism or no specified notice period for non-renewal.
- Excessively long auto-renewal notice periods (90+ days) that make it easy to miss the non-renewal window.
- Perpetual agreements with no termination-for-convenience clause (locked in indefinitely).
- Ambiguous start dates ("to be determined", "upon mutual agreement") with no mechanism to establish certainty.
- Initial term exceeding 36 months for service agreements without performance review checkpoints.
- Short initial terms (1-3 months) combined with long notice periods for non-renewal (effectively locking parties in).

### Contract Type Variations

- **Service Agreements**: Typically 12-month initial terms with annual auto-renewal. 30-60 day non-renewal notice.
- **Freelance Contracts**: Project-based duration (start date to deliverable completion). Rarely auto-renew. May specify a "not later than" end date.
- **Agency Agreements**: Often 12-24 month terms with auto-renewal. Longer non-renewal notice periods (60-90 days). May include performance benchmarks that trigger early review.
- **NDAs**: Vary widely. Mutual NDAs for business discussions often have a 2-3 year term for the agreement itself, with a separate survival period for confidentiality obligations (which may be longer). Some NDAs are perpetual.
- **Employment Contracts**: Often "at-will" (no fixed end date) in the US. Fixed-term employment contracts specify duration and may include renewal provisions. Probationary periods (30-90 days) within the initial term.

---

## 3. Intellectual Property (IP)

### What to Look For

Scan for these section headings: "Intellectual Property", "IP Rights", "Ownership", "Work Product", "Work for Hire", "License Grant", "Proprietary Rights".

Keywords and phrases within the section:
- Ownership indicators: "all rights, title, and interest", "work made for hire", "work for hire", "shall own", "assigns to", "hereby assigns"
- License indicators: "license grant", "non-exclusive license", "exclusive license", "royalty-free", "perpetual license", "worldwide"
- Pre-existing IP: "pre-existing intellectual property", "background IP", "prior inventions", "contractor tools", "retained rights"
- Moral rights: "moral rights", "waiver of moral rights", "droit moral", "right of attribution"
- Restrictions: "open source", "third-party components", "copyleft", "GPL", "creative commons"

### Common Clause Language Examples

**Full assignment (work for hire):**
> "All Work Product created by Contractor in the performance of this Agreement shall be considered 'work made for hire' as defined under the United States Copyright Act. To the extent any Work Product does not qualify as work made for hire, Contractor hereby irrevocably assigns to Client all right, title, and interest in and to such Work Product, including all intellectual property rights therein."

**License grant with retained ownership:**
> "Contractor retains all right, title, and interest in and to the Deliverables. Contractor hereby grants to Client a non-exclusive, perpetual, royalty-free, worldwide license to use, modify, and display the Deliverables for Client's internal business purposes."

**Pre-existing IP carve-out:**
> "Notwithstanding the foregoing, Contractor retains all rights in Contractor's pre-existing intellectual property, tools, frameworks, and methodologies ('Contractor Tools') listed in Exhibit B. To the extent any Contractor Tools are incorporated into the Deliverables, Contractor grants Client a non-exclusive, perpetual, royalty-free license to use such Contractor Tools solely as embedded in the Deliverables."

### Extraction Rules

- Classify IP ownership as one of: full assignment, work-for-hire, license-only, or joint ownership.
- For license grants, extract: scope (use, modify, distribute, sublicense), exclusivity (exclusive vs non-exclusive), territory (worldwide vs limited), duration (perpetual vs term-limited), fee basis (royalty-free vs paid).
- Identify pre-existing IP carve-outs and whether they are listed in an exhibit or described generically.
- Note whether moral rights are addressed (waived, preserved, or not mentioned).
- Flag any open-source or copyleft obligations that might affect the client's use of the work product.

### Red Flags

- Full IP assignment with no pre-existing IP carve-out (contractor loses rights to their own tools and frameworks).
- "Work for hire" designation applied to work that may not legally qualify under copyright law (only 9 categories qualify in the US).
- No IP clause at all in a service or freelance contract (ownership defaults to complex legal analysis).
- License grant without specifying scope, duration, or territory (ambiguous rights).
- Assignment of "all intellectual property worldwide in perpetuity" without consideration for contractor's general knowledge and skills.
- Restrictions on using similar methodologies for other clients (effective non-compete disguised as IP clause).

### Contract Type Variations

- **Service Agreements**: Typically full assignment or work-for-hire with pre-existing IP carve-out. Corporate clients expect to own all deliverables.
- **Freelance Contracts**: More variation. May range from full assignment to license-only. Freelancers often retain portfolio rights (right to display work in their portfolio).
- **Agency Agreements**: Often license-based rather than assignment-based. Agency may retain ownership of creative concepts and grant client a license. Media buys and placements may have separate IP treatment.
- **NDAs**: IP clauses in NDAs typically address ownership of ideas shared during discussions, not deliverables. "No license granted" clauses are common (sharing confidential information does not grant IP rights).
- **Employment Contracts**: Broad IP assignment ("all inventions made during employment"). May include invention assignment agreements. Watch for clauses covering work done outside of employment hours.

---

## 4. Confidentiality

### What to Look For

Scan for these section headings: "Confidentiality", "Non-Disclosure", "Confidential Information", "Proprietary Information", "Trade Secrets", "Nondisclosure Obligations".

Keywords and phrases within the section:
- Definition indicators: "confidential information means", "confidential information includes", "proprietary information shall mean"
- Scope indicators: "trade secrets", "business plans", "financial information", "customer lists", "technical data", "know-how"
- Exclusion indicators: "shall not include", "does not include", "publicly available", "independently developed", "rightfully received", "prior knowledge"
- Obligation indicators: "shall not disclose", "maintain in confidence", "use commercially reasonable efforts", "same degree of care"
- Survival indicators: "survival period", "shall survive", "for a period of", "in perpetuity"
- Return/destroy indicators: "return or destroy", "certify destruction", "upon termination", "upon written request"

### Common Clause Language Examples

**Standard mutual confidentiality:**
> "Each party (the 'Receiving Party') agrees to maintain in confidence all Confidential Information of the other party (the 'Disclosing Party') and shall not disclose such Confidential Information to any third party without the prior written consent of the Disclosing Party. The Receiving Party shall use at least the same degree of care to protect the Disclosing Party's Confidential Information as it uses to protect its own confidential information, but in no event less than reasonable care."

**Broad definition with exclusions:**
> "'Confidential Information' means all information, whether written, oral, or electronic, disclosed by either party, including but not limited to trade secrets, business plans, customer lists, financial information, technical specifications, and software code. Confidential Information shall not include information that: (a) is or becomes publicly available through no fault of the Receiving Party; (b) was rightfully in the Receiving Party's possession prior to disclosure; (c) is independently developed by the Receiving Party without reference to the Confidential Information; or (d) is rightfully received from a third party without restriction."

**Survival clause:**
> "The obligations of confidentiality set forth in this Section shall survive the expiration or termination of this Agreement for a period of three (3) years from the date of disclosure of the applicable Confidential Information."

### Extraction Rules

- Determine whether confidentiality obligations are mutual (both parties) or one-way (only one party discloses).
- Extract the definition of what constitutes confidential information, focusing on breadth (broad catch-all vs specific enumeration).
- List standard exclusions present. Compare against the four standard exclusions (publicly available, prior possession, independently developed, third-party receipt).
- Extract the survival period. Convert to months or years. "Perpetual" or "in perpetuity" means no expiration.
- Note the standard of care required: "reasonable care", "same degree of care as own information", or specific security requirements.
- Identify permitted disclosures: employees on a need-to-know basis, legal advisors, as required by law, with prior written consent.

### Red Flags

- One-way confidentiality obligations when the relationship involves mutual information sharing.
- No standard exclusions (receiving party is bound even if they independently develop the same information).
- Perpetual confidentiality obligations with no sunset provision (indefinite risk).
- Overly broad definition that could encompass publicly known industry information.
- No "required by law" exception (receiving party may be forced to choose between breaching the contract or violating a subpoena/court order).
- "Residuals" clause absent (question of whether receiving party can use general knowledge gained during the relationship).
- Return-or-destroy obligation with no exception for archival copies required by law or internal compliance policies.

### Contract Type Variations

- **NDAs**: Confidentiality is the core purpose. Expect detailed definitions, specific exclusions, clear survival periods, and return/destroy obligations. Mutual NDAs have symmetric obligations.
- **Service Agreements**: Confidentiality is typically a supporting section. May reference a separate NDA or contain a self-contained confidentiality clause. Focus is on protecting client data encountered during service delivery.
- **Freelance Contracts**: Often include confidentiality provisions to protect client information shared with the freelancer. May be one-way (client's information only).
- **Agency Agreements**: Bidirectional confidentiality is common. Agency protects client's business strategy; client protects agency's proprietary methodologies and pricing.
- **Employment Contracts**: Confidentiality obligations typically survive termination of employment. May be linked to non-compete and non-solicitation provisions. Often reference a separate Confidential Information and Invention Assignment Agreement (CIIAA).

---

## 5. Liability

### What to Look For

Scan for these section headings: "Liability", "Limitation of Liability", "Indemnification", "Indemnity", "Hold Harmless", "Damages", "Insurance".

Keywords and phrases within the section:
- Cap indicators: "aggregate liability shall not exceed", "total liability", "maximum liability", "in no event shall", "cap"
- Exclusion indicators: "consequential damages", "incidental damages", "indirect damages", "lost profits", "punitive damages", "special damages"
- Indemnification indicators: "indemnify and hold harmless", "defend, indemnify", "at its sole expense", "third-party claims"
- Insurance indicators: "general liability insurance", "professional liability", "errors and omissions", "workers' compensation", "certificate of insurance"
- Mutual indicators: "each party shall indemnify", "mutual indemnification"

### Common Clause Language Examples

**Liability cap tied to fees paid:**
> "IN NO EVENT SHALL EITHER PARTY'S AGGREGATE LIABILITY ARISING OUT OF OR RELATED TO THIS AGREEMENT EXCEED THE TOTAL AMOUNTS PAID OR PAYABLE BY CLIENT TO CONTRACTOR UNDER THIS AGREEMENT DURING THE TWELVE (12) MONTH PERIOD PRECEDING THE CLAIM."

**Consequential damages exclusion:**
> "IN NO EVENT SHALL EITHER PARTY BE LIABLE TO THE OTHER FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, INCLUDING BUT NOT LIMITED TO LOSS OF PROFITS, LOSS OF DATA, OR BUSINESS INTERRUPTION, REGARDLESS OF THE CAUSE OF ACTION OR THE THEORY OF LIABILITY, EVEN IF SUCH PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES."

**One-way indemnification:**
> "Contractor shall indemnify, defend, and hold harmless Client and its officers, directors, employees, and agents from and against any and all claims, damages, losses, costs, and expenses (including reasonable attorneys' fees) arising out of or related to: (a) Contractor's breach of this Agreement; (b) Contractor's negligence or willful misconduct; or (c) any third-party claim that the Deliverables infringe such third party's intellectual property rights."

### Extraction Rules

- Extract liability caps as specific dollar amounts or as formulas (e.g., "total fees paid in the preceding 12 months", "2x the fees paid under the applicable SOW").
- Identify which damage types are excluded and whether exclusions are mutual or one-sided.
- For indemnification, determine: who indemnifies whom (mutual vs one-way), what is covered (breach, negligence, IP infringement, third-party claims), and who controls the defense.
- Extract insurance requirements: types of coverage required, minimum amounts, whether certificates must be provided, additional insured requirements.
- Note whether liability provisions are written in ALL CAPS (common for enforceability under UCC and many state laws).

### Red Flags

- No liability cap at all (unlimited liability exposure).
- One-sided liability cap that protects only one party.
- Liability cap set below the contract value (e.g., cap of $1,000 on a $50,000 engagement).
- One-way indemnification without reciprocal protection.
- Indemnification covering the indemnifying party's own negligence (one-sided risk allocation).
- No consequential damages exclusion (exposure to lost profits claims).
- Insurance requirements disproportionate to contract value (e.g., $5M policy required for a $10,000 project).
- "Sole remedy" provisions that limit recourse to refund-only (no ability to seek other damages).

### Contract Type Variations

- **Service Agreements**: Typically include mutual liability caps tied to fees paid (12-month lookback), mutual consequential damages exclusions, and mutual indemnification for breach and negligence. Insurance requirements are common.
- **Freelance Contracts**: Liability caps are less common but important. May cap liability at total fees paid. Indemnification often one-way (freelancer indemnifies client). Insurance requirements are rare for small engagements.
- **Agency Agreements**: Higher liability exposure due to public-facing work. May include specific indemnification for advertising claims, trademark infringement, and regulatory violations. Insurance requirements (E&O, media liability) are standard.
- **NDAs**: Liability provisions are minimal in standalone NDAs. May include acknowledgment that breach could cause irreparable harm (basis for injunctive relief). Damages caps are uncommon.
- **Employment Contracts**: Liability provisions are typically implicit (governed by employment law). May include non-liability provisions for the employer regarding at-will termination. Indemnification of the employee for actions within scope of employment is sometimes included.

---

## 6. Termination

### What to Look For

Scan for these section headings: "Termination", "Term and Termination", "Cancellation", "Expiration", "Default", "Breach".

Keywords and phrases within the section:
- Cause indicators: "terminate for cause", "material breach", "default", "insolvency", "bankruptcy", "failure to perform"
- Convenience indicators: "terminate for convenience", "terminate at any time", "without cause", "for any reason or no reason"
- Notice indicators: "written notice", "days prior notice", "calendar days", "business days", "effective upon receipt"
- Cure indicators: "cure period", "opportunity to cure", "right to remedy", "within [X] days of notice"
- Post-termination indicators: "upon termination", "wind-down", "transition", "return of materials", "final payment", "accrued obligations"
- Survival indicators: "shall survive termination", "surviving provisions", "sections [X] through [Y] shall survive"

### Common Clause Language Examples

**Termination for cause with cure period:**
> "Either party may terminate this Agreement upon thirty (30) days' written notice to the other party if the other party materially breaches any provision of this Agreement and fails to cure such breach within thirty (30) days after receiving written notice specifying the nature of the breach."

**Termination for convenience:**
> "Either party may terminate this Agreement for any reason or no reason upon sixty (60) days' prior written notice to the other party. In the event of termination for convenience by Client, Client shall pay Contractor for all Services performed and expenses incurred through the effective date of termination."

**Post-termination obligations:**
> "Upon expiration or termination of this Agreement for any reason: (a) Client shall pay Contractor for all Services performed through the effective date of termination; (b) each party shall return or destroy all Confidential Information of the other party; (c) Contractor shall provide reasonable transition assistance for a period not to exceed thirty (30) days at Contractor's then-current hourly rate; and (d) all licenses granted hereunder shall terminate, except as expressly stated in Section 7(c)."

### Extraction Rules

- Identify all termination triggers and categorize as "for cause" or "for convenience."
- For each trigger, extract: who can invoke it (mutual, client-only, contractor-only), the notice period required, and whether a cure period applies.
- Extract cure period length and conditions (written notice, specific description of breach, opportunity to remedy).
- List post-termination obligations for each party.
- Identify which sections survive termination (typically Confidentiality, Liability, IP, and Dispute Resolution).
- Note whether accrued payment obligations survive termination (they should -- flag if missing).

### Red Flags

- Only one party has the right to terminate for convenience (asymmetric exit rights).
- No cure period for material breach (immediate termination without opportunity to fix).
- Very short cure periods (less than 10 days) for complex service obligations.
- No termination for convenience clause at all (parties locked in for the full term).
- Post-termination IP provisions that differ from the main IP clause (e.g., license terminates upon termination, leaving client without rights to work already paid for).
- No payment obligation for work completed before termination.
- Excessive post-termination non-compete or non-solicitation periods (more than 12 months).
- Kill fee or early termination penalty exceeding the remaining contract value.

### Contract Type Variations

- **Service Agreements**: Both for-cause and for-convenience termination. 30-day notice and 30-day cure are standard. Transition assistance provisions are common for ongoing services.
- **Freelance Contracts**: Termination for convenience is common with shorter notice (14-30 days). Kill fees or milestone-based payment on termination protect the freelancer. Cure periods may be shorter.
- **Agency Agreements**: Longer notice periods (60-90 days) to allow for campaign wind-down. May include provisions for completing work-in-progress. Transition of media accounts and vendor relationships is a key post-termination concern.
- **NDAs**: Termination provisions are simple (either party, written notice, 30 days). The critical element is the survival period for confidentiality obligations, which continues past termination.
- **Employment Contracts**: Termination is heavily governed by employment law. At-will provisions in the US. Notice periods vary by jurisdiction internationally. Severance provisions, garden leave, and COBRA benefits continuation may apply.

---

## 7. Warranty

### What to Look For

Scan for these section headings: "Warranty", "Warranties", "Representations and Warranties", "Disclaimer", "Disclaimer of Warranties", "Guarantees", "Remedy".

Keywords and phrases within the section:
- Affirmative warranty indicators: "represents and warrants", "warrants that", "guarantees that", "covenants that"
- Quality indicators: "workmanlike manner", "professional standards", "industry standards", "merchantability", "fitness for a particular purpose"
- Disclaimer indicators: "as is", "as available", "no warranty", "expressly disclaims", "without warranty of any kind"
- Period indicators: "warranty period", "for a period of [X] days", "from the date of delivery", "acceptance period"
- Remedy indicators: "sole remedy", "exclusive remedy", "re-perform", "correct defects", "refund"

### Common Clause Language Examples

**Professional standards warranty:**
> "Contractor represents and warrants that: (a) the Services shall be performed in a professional and workmanlike manner consistent with generally accepted industry standards; (b) the Deliverables shall conform in all material respects to the specifications set forth in Exhibit A; and (c) Contractor has the right and authority to enter into this Agreement and to perform its obligations hereunder."

**Disclaimer of implied warranties:**
> "EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, NEITHER PARTY MAKES ANY WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION ANY IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, OR NON-INFRINGEMENT. THE DELIVERABLES ARE PROVIDED 'AS IS' TO THE MAXIMUM EXTENT PERMITTED BY APPLICABLE LAW."

**Warranty period with remedies:**
> "Contractor warrants that the Deliverables shall be free from material defects for a period of ninety (90) days following Client's acceptance (the 'Warranty Period'). During the Warranty Period, if Client identifies a material defect, Contractor shall, at its sole expense, correct such defect within fifteen (15) business days of receiving written notice. If Contractor fails to correct the defect within such period, Client's sole and exclusive remedy shall be a pro-rata refund of the fees attributable to the defective Deliverable."

### Extraction Rules

- List all affirmative warranties made by each party separately.
- Identify which implied warranties are disclaimed (merchantability, fitness for particular purpose, non-infringement) and whether disclaimers are mutual.
- Extract the warranty period: start date trigger (delivery, acceptance, go-live), duration, and what happens after expiration.
- Extract remedies for warranty breach: correction/re-performance, replacement, refund, or other specific remedies.
- Note whether remedies are designated as the "sole and exclusive" remedy (limiting the aggrieved party's options).
- Identify representations about authority, non-infringement, and compliance with laws (these are warranties even when labeled "representations").

### Red Flags

- Complete "as is" disclaimer on custom-developed work product (client pays for work with no quality guarantee).
- No warranty period at all (defects discovered after delivery have no contractual remedy).
- "Sole remedy" limited to re-performance only (no refund option if correction fails).
- Very short warranty periods (less than 30 days) for complex deliverables.
- Warranty disclaimed for the specific purpose the work is being commissioned for (fitness for a particular purpose disclaimed in a contract where the purpose is clearly stated).
- One-sided warranty obligations (one party makes extensive warranties while the other disclaims everything).
- Missing non-infringement warranty (no protection against third-party IP claims related to deliverables).
- Warranty contingent on conditions not within the client's control ("warranty void if used with third-party software").

### Contract Type Variations

- **Service Agreements**: Typically warrant professional and workmanlike performance consistent with industry standards. 30-90 day warranty periods on deliverables. Remedies include correction, re-performance, and potentially a refund.
- **Freelance Contracts**: May have simpler warranty language. "Workmanlike manner" is standard. Warranty periods are often shorter (30-60 days). Remedies tend toward revision rounds rather than refunds.
- **Agency Agreements**: Warranties cover both the quality of creative work and factual accuracy of content. Media placements may carry separate warranties (correct placement, agreed-upon audience). Compliance with advertising regulations is a common warranty.
- **NDAs**: Warranties are minimal. Parties typically warrant authority to enter the agreement and that disclosed information is not subject to third-party restrictions that would prevent disclosure.
- **Employment Contracts**: Warranty-like provisions focus on the employee's representations about qualifications, absence of conflicting obligations (non-competes with prior employers), and right to work authorization. The employer may warrant the accuracy of the job description and compensation terms.
