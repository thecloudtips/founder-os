# Risk Pattern Library

Comprehensive risk pattern detection reference for the legal-risk-detection skill. Organized by severity tier. Each pattern includes detection phrases, example clause text, plain-English risk explanation, and mitigation language.

When scanning a contract, evaluate each clause against the patterns below. Match detection phrases case-insensitively. A single clause may match multiple patterns -- assign the highest applicable severity. When a clause partially matches a pattern, use judgment to determine if the match is close enough to flag. Err on the side of flagging (false positives are preferable to missed risks for the target audience).

---

## Red (High Risk) Patterns

Red patterns represent clauses that could cause significant financial or legal harm. Every Red flag should include a recommendation to consult a lawyer before signing.

---

### R01: One-Sided Indemnification

- **Category**: Liability Risk
- **Detection phrases**: "contractor shall indemnify", "service provider agrees to indemnify, defend, and hold harmless", "vendor shall be solely responsible for", "indemnify and hold harmless the client" (without reciprocal language)
- **Example clause**: "Contractor shall indemnify, defend, and hold harmless Client, its officers, directors, employees, and agents from and against any and all claims, damages, losses, liabilities, costs, and expenses (including reasonable attorneys' fees) arising out of or related to Contractor's performance under this Agreement."
- **Why it's risky**: The contractor absorbs all legal and financial risk, including claims that may originate from the client's own actions or decisions. If a client's customer sues over a deliverable the client directed the contractor to build, the contractor pays for the defense. There is no reciprocal protection -- the client owes no indemnification to the contractor.
- **Mitigation**: "Replace one-sided indemnification with mutual indemnification: each party indemnifies the other for claims arising from their own negligence or breach. If mutual indemnification is refused, cap indemnification at the total fees paid under the contract."

---

### R02: Unlimited Liability

- **Category**: Liability Risk
- **Detection phrases**: "no limitation on liability", "contractor's liability shall not be limited", "unlimited liability", absence of any limitation of liability section, "liable for all damages without limitation"
- **Example clause**: "Contractor shall be liable for any and all damages, whether direct, indirect, incidental, consequential, special, or punitive, arising from Contractor's breach of this Agreement, without limitation."
- **Why it's risky**: Without a liability cap, a minor contract breach could result in damages that vastly exceed the contract value. A $10,000 project could generate a $500,000 liability claim. This is one of the most dangerous clauses a freelancer can sign.
- **Mitigation**: "Add a limitation of liability clause capping total liability at 1x-2x the total fees paid under the contract. Exclude consequential and punitive damages. Standard language: 'In no event shall either party's total liability exceed the aggregate fees paid or payable under this Agreement during the twelve (12) months preceding the claim.'"

---

### R03: Perpetual IP Assignment

- **Category**: IP Risk
- **Detection phrases**: "all work product shall be the sole and exclusive property of Client in perpetuity", "irrevocable, perpetual, worldwide assignment", "all intellectual property rights, in perpetuity, throughout the universe", "work product created at any time"
- **Example clause**: "All Work Product, including all intellectual property rights therein, shall be the sole and exclusive property of Client in perpetuity. Contractor hereby irrevocably assigns to Client all right, title, and interest in and to all Work Product, whether created during or after the term of this Agreement."
- **Why it's risky**: Perpetual IP assignment with no reversion means everything the contractor creates belongs to the client forever -- even after the contract ends. The "during or after" language could be interpreted to cover work the contractor creates independently after the engagement. There is no mechanism to recover rights if the client never uses the work.
- **Mitigation**: "Limit IP assignment to deliverables specifically created for this engagement. Add a pre-existing IP carve-out: 'Contractor retains all rights to pre-existing IP, tools, frameworks, and methodologies.' Add a reversion clause: 'If Client does not commercially use the Work Product within 24 months, all rights revert to Contractor.'"

---

### R04: Work-for-Hire With No Pre-Existing IP Carve-Out

- **Category**: IP Risk
- **Detection phrases**: "work made for hire", "all work shall be considered work for hire", "all materials, code, designs, and work product" (without an exclusion for pre-existing IP)
- **Example clause**: "All Work Product created by Contractor under this Agreement shall be considered 'work made for hire' as defined by the Copyright Act. To the extent any Work Product does not qualify as work made for hire, Contractor hereby assigns all right, title, and interest to Client."
- **Why it's risky**: Without a carve-out for pre-existing IP, the contractor risks losing ownership of tools, code libraries, frameworks, and methodologies developed before the engagement. If the contractor uses a proprietary code snippet in the deliverable, the client could claim ownership of that snippet -- and the contractor could lose the right to use it on other projects.
- **Mitigation**: "Add a pre-existing IP schedule listing all tools, libraries, and frameworks the contractor brings to the project. Standard language: 'Notwithstanding the foregoing, Contractor retains all right, title, and interest in Contractor's pre-existing intellectual property as identified in Schedule [X]. Client is granted a non-exclusive, perpetual license to use such pre-existing IP solely as embedded in the Deliverables.'"

---

### R05: Unilateral Termination Without Payment for Completed Work

- **Category**: Termination Risk
- **Detection phrases**: "Client may terminate at any time without cause", "upon termination, Contractor shall not be entitled to any further compensation", "all unpaid amounts shall be forfeited upon termination", "Client may terminate immediately"
- **Example clause**: "Client may terminate this Agreement at any time, for any reason or no reason, upon written notice to Contractor. Upon such termination, Client shall have no further payment obligations to Contractor, and Contractor shall immediately deliver all Work Product completed to date."
- **Why it's risky**: The client can terminate at any point and receive all completed work without paying for it. The contractor bears all financial risk of project cancellation. This is especially dangerous on long-term projects where weeks or months of work may be unpaid.
- **Mitigation**: "Require payment for all work completed through the termination date. Standard language: 'Upon termination for convenience by Client, Client shall pay Contractor for all services performed and expenses incurred through the effective date of termination, plus a kill fee of [15-25]% of the remaining contract value.' Also require a minimum notice period (30 days for engagements over 3 months)."

---

### R06: Non-Compete Exceeding 2 Years or Unreasonably Broad

- **Category**: Non-Compete Risk
- **Detection phrases**: "shall not engage in any business that competes", "non-compete period of [>24] months", "shall not provide services to any competitor", "worldwide non-compete", "any industry related to"
- **Example clause**: "For a period of thirty-six (36) months following the termination of this Agreement, Contractor shall not directly or indirectly provide services to, or engage in business with, any entity that competes with Client or any of Client's affiliates in any market worldwide."
- **Why it's risky**: A 3-year worldwide non-compete could prevent the contractor from working in their entire professional domain. For freelancers, this effectively means unemployment for the restricted period. "Any entity that competes" combined with "affiliates" and "worldwide" makes the restriction nearly impossible to comply with if the client operates in a broad market.
- **Mitigation**: "Narrow the non-compete to a maximum of 6-12 months for freelancers (12-18 months for agencies). Limit geographic scope to the specific market where the client operates. Define 'competitor' narrowly by naming specific companies or defining the competitive space precisely. Add compensation during the restriction period: 'Client shall pay Contractor [50]% of the average monthly fee during the non-compete period.'"

---

### R07: Perpetual Confidentiality With No Sunset

- **Category**: Confidentiality Risk
- **Detection phrases**: "obligations shall survive in perpetuity", "confidentiality obligations shall have no expiration", "shall remain confidential indefinitely", "for an unlimited period following termination"
- **Example clause**: "Contractor's obligations under this Section shall survive the termination or expiration of this Agreement and shall continue in perpetuity. Contractor shall not, at any time, disclose, publish, or otherwise reveal any Confidential Information to any third party."
- **Why it's risky**: Perpetual confidentiality means the contractor must track and protect the client's information forever -- even decades after the engagement ends. Over time, it becomes impossible to reliably distinguish what was learned from this client versus general professional knowledge. Perpetual obligations also create indefinite legal exposure.
- **Mitigation**: "Set a reasonable survival period: 2-3 years for general business information, 5 years for trade secrets. Standard language: 'The obligations of confidentiality shall survive for a period of three (3) years following the termination of this Agreement, except with respect to trade secrets, which shall remain confidential for so long as they qualify as trade secrets under applicable law.'"

---

### R08: Pay-When-Paid Clauses

- **Category**: Payment Risk
- **Detection phrases**: "payment shall be made upon receipt of payment from", "contingent upon Client receiving payment from its customer", "pay-when-paid", "payment conditional on end-client funding", "Contractor will be paid when Client is paid"
- **Example clause**: "Client's obligation to pay Contractor is contingent upon Client receiving corresponding payment from its end customer. In the event that Client's customer fails to pay, Client shall have no obligation to compensate Contractor for services rendered."
- **Why it's risky**: The contractor's payment depends on a third party the contractor has no relationship with and no visibility into. The contractor bears the client's business risk -- if the client's customer goes bankrupt or disputes an invoice, the contractor works for free. This is one of the most financially dangerous clauses for freelancers.
- **Mitigation**: "Remove pay-when-paid language entirely. Payment obligations should be between the contracting parties only. If the client insists on cash flow alignment, propose: 'Client shall pay Contractor within [30] days of invoice date, regardless of Client's receipt of payment from third parties. Client may negotiate a payment schedule aligned with project milestones but not contingent on third-party payment.'"

---

### R09: Automatic Scope Expansion

- **Category**: Scope Risk
- **Detection phrases**: "and any other tasks as reasonably requested", "including but not limited to", "and such other duties as may be assigned", "all work reasonably necessary to complete the project", "any additional services as Client may request"
- **Example clause**: "Contractor shall perform the services described in Exhibit A, as well as any other tasks reasonably requested by Client from time to time in connection with the Project."
- **Why it's risky**: This language allows the client to expand the scope indefinitely without renegotiating compensation. "Reasonably requested" is subjective and undefined. The contractor could be asked to perform work far beyond the original agreement with no recourse to decline or request additional payment.
- **Mitigation**: "Replace open-ended scope language with a defined change order process. Standard language: 'Any services not explicitly described in Exhibit A shall be considered out of scope. Out-of-scope requests shall be documented in a written Change Order signed by both parties, specifying the additional scope, timeline impact, and additional fees before work begins.'"

---

### R10: No Cure Period for Breach

- **Category**: Termination Risk
- **Detection phrases**: "immediate termination upon breach", "may terminate immediately upon any breach", "Contractor's breach of any term shall result in immediate termination", absence of "cure" or "remedy" language in the termination section
- **Example clause**: "In the event of any breach of this Agreement by Contractor, Client may immediately terminate this Agreement and pursue all available legal remedies."
- **Why it's risky**: Without a cure period, a minor, easily fixable mistake (a missed email, a small deliverable delay) can result in immediate contract termination and potential legal action. Standard contracts allow a window (typically 15-30 days) to fix the problem before termination takes effect.
- **Mitigation**: "Add a cure period. Standard language: 'In the event of a material breach, the non-breaching party shall provide written notice specifying the breach. The breaching party shall have thirty (30) days to cure the breach. If the breach is not cured within the cure period, the non-breaching party may terminate this Agreement.' Apply the cure period to both parties."

---

### R11: Moral Rights Waiver

- **Category**: IP Risk
- **Detection phrases**: "waives all moral rights", "contractor waives any and all rights of attribution", "waives droit moral", "irrevocably waives all moral rights of authorship"
- **Example clause**: "To the extent permitted by applicable law, Contractor hereby irrevocably waives and agrees not to assert any and all moral rights, including rights of attribution and integrity, that Contractor may have in the Work Product."
- **Why it's risky**: In jurisdictions that recognize moral rights (EU, UK, Canada, Australia), this waiver strips the contractor of the right to be credited for their work and the right to prevent modifications that damage their reputation. While moral rights cannot be waived in some jurisdictions (making this clause unenforceable), the inclusion signals aggressive IP posturing by the client.
- **Mitigation**: "Request removal of the moral rights waiver. If the client requires it for downstream licensing, propose: 'Contractor waives moral rights solely to the extent necessary for Client to use, modify, and sublicense the Deliverables for their intended commercial purpose. Contractor retains the right of attribution in portfolio use.' Note: In many jurisdictions, moral rights waivers are unenforceable regardless of contractual language."

---

### R12: Retroactive IP Assignment

- **Category**: IP Risk
- **Detection phrases**: "including work performed prior to the effective date", "all work product created before, during, or after", "retroactively assigns", "any work performed in connection with discussions prior to execution"
- **Example clause**: "Contractor hereby assigns to Client all right, title, and interest in any work product created in connection with the Project, including any work performed during preliminary discussions, proposals, or pitches prior to the effective date of this Agreement."
- **Why it's risky**: The contractor loses ownership of work created during the sales process -- proposals, mockups, prototypes, and pitch materials. This work was created before any contract existed and before any payment was agreed. If the deal falls through later, the client retains the pre-contract work with no compensation.
- **Mitigation**: "Limit IP assignment to work created after the effective date. Standard language: 'IP assignment under this Agreement applies solely to Deliverables created on or after the Effective Date. All work product created prior to the Effective Date, including proposals, mockups, and pitch materials, remains the property of Contractor.' If pre-contract work is incorporated into deliverables, grant a license rather than an assignment."

---

### R13: Penalty Clauses Exceeding Contract Value

- **Category**: Liability Risk
- **Detection phrases**: "liquidated damages of", "penalty of [amount exceeding contract value]", "Contractor shall pay Client [disproportionate amount]", "damages in the amount of"
- **Example clause**: "In the event Contractor fails to deliver any Milestone by its due date, Contractor shall pay Client liquidated damages of $5,000 per day of delay, up to a maximum of $250,000."
- **Why it's risky**: When penalty amounts exceed the total contract value, the contractor faces financial ruin from relatively minor delays. A $50,000 project with $250,000 in penalty exposure means the contractor could owe 5x what they were paid. Liquidated damages clauses that are disproportionate to actual harm may be unenforceable, but defending against them is expensive.
- **Mitigation**: "Cap liquidated damages at a percentage of the contract value (10-15% is standard). Standard language: 'Liquidated damages for late delivery shall not exceed [10]% of the total fees payable under this Agreement. Liquidated damages represent the parties' reasonable estimate of actual damages and are not intended as a penalty.' Alternatively, negotiate a credit system rather than cash penalties."

---

### R14: Forum Selection in Distant/Unfavorable Jurisdiction

- **Category**: Liability Risk
- **Detection phrases**: "exclusive jurisdiction of the courts of [distant location]", "shall be governed by the laws of [unfamiliar jurisdiction]", "all disputes shall be resolved in [client's home state/country]", "venue shall be exclusively in"
- **Example clause**: "This Agreement shall be governed by and construed in accordance with the laws of the State of Delaware, and all disputes shall be resolved exclusively in the state or federal courts located in Wilmington, Delaware."
- **Why it's risky**: If a dispute arises, the contractor must travel to the client's chosen jurisdiction to pursue or defend a claim. For a freelancer in California forced to litigate in Delaware (or worse, in a foreign country), the travel costs and local counsel fees may exceed the contract value, effectively denying access to justice.
- **Mitigation**: "Propose contractor's home jurisdiction, or agree on a neutral jurisdiction. For remote engagements, propose virtual arbitration: 'Any disputes shall be resolved by binding arbitration administered by [JAMS/AAA] conducted remotely via videoconference, applying the laws of [contractor's state].' If the client insists on their jurisdiction, negotiate a minimum dispute threshold ($10,000+) below which claims must be resolved informally."

---

### R15: Waiver of Jury Trial With Client-Chosen Arbitrator

- **Category**: Liability Risk
- **Detection phrases**: "waives the right to a jury trial", "mandatory binding arbitration", "arbitration shall be conducted by an arbitrator selected by Client", "administered by [client-selected arbitration body]"
- **Example clause**: "The parties waive any right to a trial by jury. All disputes shall be resolved by mandatory binding arbitration conducted by a single arbitrator selected by Client, in Client's principal place of business."
- **Why it's risky**: Combining a jury trial waiver with client-selected arbitration creates a structurally biased dispute resolution process. The client chooses the arbitrator and the location, and the contractor has waived the right to a jury. Arbitration also typically limits discovery and appeal rights, which can disadvantage the party with less information (usually the contractor).
- **Mitigation**: "If arbitration is required, ensure neutral arbitrator selection. Standard language: 'Disputes shall be resolved by binding arbitration administered by [JAMS or AAA] under their applicable rules. The arbitrator shall be mutually agreed upon by the parties, or appointed by the administering body if the parties cannot agree.' Retain the right to seek injunctive relief in court for IP and confidentiality breaches."

---

## Yellow (Medium Risk) Patterns

Yellow patterns represent clauses that deviate from standard practice or contain ambiguity. They may be acceptable depending on context but should be reviewed carefully.

---

### Y01: Vague Confidentiality Scope

- **Category**: Confidentiality Risk
- **Detection phrases**: "all information shared between the parties", "any and all information, whether written or oral", "all information related to Client's business", "any information disclosed"
- **Example clause**: "Contractor agrees to hold in confidence all information shared by Client, whether written, oral, electronic, or otherwise, and shall not disclose such information to any third party."
- **Why it's risky**: "All information shared" is so broad that it could include publicly available information, casual conversations, and general industry knowledge. The contractor may inadvertently breach confidentiality by discussing publicly known facts about the client's industry.
- **Mitigation**: "Define confidential information specifically. Propose: 'Confidential Information means information that is (a) marked as confidential at the time of disclosure, or (b) identified as confidential in writing within five (5) business days of oral disclosure. Confidential Information excludes information that is publicly available, independently developed, or received from a third party without restriction.'"

---

### Y02: Ambiguous Payment Terms

- **Category**: Payment Risk
- **Detection phrases**: "payment shall be made in a timely manner", "upon completion", "payment terms to be agreed", "reasonable time after invoice", absence of specific net-N terms
- **Example clause**: "Client shall pay Contractor for services rendered in a timely manner upon receipt of invoice."
- **Why it's risky**: "Timely manner" is undefined -- it could mean 15 days or 90 days. Without a specific payment window, the contractor has no contractual basis to enforce prompt payment or charge late fees. Disputes about what constitutes "timely" are difficult and expensive to resolve.
- **Mitigation**: "Specify exact payment terms. Propose: 'Client shall pay each invoice within thirty (30) days of receipt (Net-30). Late payments shall accrue interest at the rate of 1.5% per month or the maximum rate permitted by law, whichever is less. Contractor may suspend work if any invoice remains unpaid for more than fifteen (15) days past due.'"

---

### Y03: Broad Non-Solicitation

- **Category**: Non-Compete Risk
- **Detection phrases**: "shall not solicit or hire any employee, contractor, or customer of Client", "non-solicitation period of [>12] months", "shall not engage with any of Client's customers"
- **Example clause**: "For a period of eighteen (18) months following termination, Contractor shall not directly or indirectly solicit, hire, or engage any employee, contractor, consultant, or customer of Client."
- **Why it's risky**: Broad non-solicitation that includes customers (not just employees) can prevent the contractor from working with companies they may have had independent relationships with before the engagement. An 18-month period is longer than standard for non-solicitation.
- **Mitigation**: "Limit non-solicitation to employees only (not customers or contractors), and reduce the period to 12 months. Propose: 'For a period of twelve (12) months following termination, Contractor shall not directly solicit for employment any employee of Client with whom Contractor worked during the engagement. This restriction does not apply to general job postings or inbound inquiries.'"

---

### Y04: Auto-Renewal Without Clear Opt-Out

- **Category**: Termination Risk
- **Detection phrases**: "shall automatically renew", "unless either party provides notice", "this Agreement will renew for successive [period] terms", auto-renewal language without specifying the notice window
- **Example clause**: "This Agreement shall automatically renew for successive one-year terms unless either party provides written notice of non-renewal."
- **Why it's risky**: Without a specified notice period, the contractor may miss the window to opt out and be locked into another term. Some auto-renewal clauses bury the notice requirement or set an unreasonably early notice deadline (e.g., 90 days before the renewal date).
- **Mitigation**: "Specify a reasonable notice period. Propose: 'This Agreement shall automatically renew for successive [period] terms unless either party provides written notice of non-renewal at least thirty (30) days prior to the end of the then-current term. Notice may be provided by email to the addresses specified in this Agreement.'"

---

### Y05: Vague Deliverable Definitions

- **Category**: Scope Risk
- **Detection phrases**: "satisfactory completion", "as determined by Client", "to Client's satisfaction", "deliverables as described in the proposal", undefined exhibit references
- **Example clause**: "Contractor shall deliver the Project to Client's satisfaction. Final acceptance shall be at Client's sole discretion."
- **Why it's risky**: "Client's sole discretion" is a subjective standard with no objective criteria. The client could reject completed work indefinitely, withholding payment for work that meets every reasonable standard. The contractor has no recourse if the client simply says "I'm not satisfied."
- **Mitigation**: "Define objective acceptance criteria. Propose: 'Deliverables shall be deemed accepted if they materially conform to the specifications in Exhibit A. Client shall have ten (10) business days to review each Deliverable and provide specific, written feedback. If Client does not respond within the review period, the Deliverable shall be deemed accepted. Rejection must specify the deficiency with reference to the applicable specification.'"

---

### Y06: Assignment Clause Allowing Client Transfer Without Consent

- **Category**: Termination Risk
- **Detection phrases**: "Client may assign this Agreement without Contractor's consent", "freely assignable by Client", "Client may transfer its rights and obligations"
- **Example clause**: "Client may assign this Agreement or any rights hereunder to any successor, affiliate, or acquirer without the prior consent of Contractor."
- **Why it's risky**: The contractor chose to work with a specific client. If the client can assign the contract to any entity -- including a competitor, a company the contractor has conflicts with, or an entity with poor payment history -- the contractor has no say. The contractor could end up obligated to work for a company they would never have agreed to work with.
- **Mitigation**: "Require mutual consent for assignment. Propose: 'Neither party may assign this Agreement without the prior written consent of the other party, which shall not be unreasonably withheld. Assignment in connection with a merger, acquisition, or reorganization shall require notice to the other party at least thirty (30) days in advance.'"

---

### Y07: Unclear Expense Reimbursement

- **Category**: Payment Risk
- **Detection phrases**: "reasonable expenses", "pre-approved expenses", "expenses as agreed", absence of specific expense terms when travel or materials are expected
- **Example clause**: "Client shall reimburse Contractor for reasonable, pre-approved expenses incurred in connection with the Project."
- **Why it's risky**: "Reasonable" and "pre-approved" are vague. Without defined categories, approval processes, or reimbursement timelines, the contractor may incur expenses that the client later disputes as unreasonable or not properly pre-approved.
- **Mitigation**: "Define expense categories and approval thresholds. Propose: 'Client shall reimburse Contractor for the following expense categories: travel, accommodation, software licenses, and third-party services. Expenses under $[250] require email pre-approval. Expenses over $[250] require written approval via Change Order. Reimbursement shall be processed within the same payment cycle as the next invoice.'"

---

### Y08: Insurance Requirements Without Specified Minimums

- **Category**: Liability Risk
- **Detection phrases**: "Contractor shall maintain adequate insurance", "appropriate insurance coverage", "insurance as reasonably required", "professional liability insurance"
- **Example clause**: "Contractor shall maintain professional liability insurance and general commercial liability insurance in amounts adequate to cover potential claims arising under this Agreement."
- **Why it's risky**: "Adequate" is undefined. The client could later claim the contractor's coverage was insufficient, creating a breach of contract argument. Without specified minimums, the contractor cannot budget for insurance costs or verify compliance.
- **Mitigation**: "Specify insurance types and minimums. Propose: 'Contractor shall maintain: (a) professional liability / errors and omissions insurance with a minimum coverage of $[1,000,000] per occurrence, and (b) general commercial liability insurance with a minimum coverage of $[1,000,000] per occurrence. Contractor shall provide a certificate of insurance upon request.'"

---

### Y09: Broad Representations and Warranties

- **Category**: Liability Risk
- **Detection phrases**: "Contractor represents and warrants that all Work Product shall be free from defects", "warrants that services will be performed in a professional and workmanlike manner and shall achieve all desired results", "Contractor warrants fitness for a particular purpose"
- **Example clause**: "Contractor represents and warrants that all Work Product delivered hereunder shall be free from defects, errors, and omissions and shall perform in accordance with Client's expectations and requirements."
- **Why it's risky**: "Free from defects" and "perform in accordance with Client's expectations" are warranty standards that are impossible to meet absolutely. Software always has bugs. Creative work is subjective. These warranties create exposure to breach claims for minor, inevitable imperfections.
- **Mitigation**: "Limit warranties to professional standards. Propose: 'Contractor warrants that services shall be performed in a professional and workmanlike manner consistent with generally accepted industry standards. EXCEPT AS EXPRESSLY STATED IN THIS AGREEMENT, CONTRACTOR DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.' Add a warranty period (30-90 days) after which warranty claims expire."

---

### Y10: Low Limitation of Liability Relative to Contract Value

- **Category**: Liability Risk
- **Detection phrases**: "total liability shall not exceed $[low amount]", "aggregate liability limited to [amount far below contract value]"
- **Example clause**: "In no event shall Client's total liability to Contractor under this Agreement exceed one thousand dollars ($1,000)."
- **Why it's risky**: When the client's liability cap is set far below the contract value (e.g., $1,000 cap on a $50,000 engagement), the contractor effectively has no meaningful recourse if the client breaches. The asymmetry between what the contractor is owed and what they can recover makes the contract one-sided.
- **Mitigation**: "Set mutual liability caps at 1x-2x the total contract value. Propose: 'Each party's total aggregate liability under this Agreement shall not exceed the total fees paid or payable during the twelve (12) months preceding the claim. This limitation applies equally to both parties.'"

---

### Y11: Governing Law in Neither Party's Jurisdiction

- **Category**: Liability Risk
- **Detection phrases**: "governed by the laws of [state/country neither party is located in]", "construed in accordance with the laws of [unrelated jurisdiction]"
- **Example clause**: "This Agreement shall be governed by and construed in accordance with the laws of the State of New York, without regard to conflict of law principles."
- **Why it's risky**: When neither party is in New York (or whatever the chosen jurisdiction), both parties face unfamiliar legal territory. Legal fees increase because both sides need local counsel. The choice may favor one party's legal strategy without clear justification.
- **Mitigation**: "Propose the contractor's home jurisdiction or agree on a jurisdiction where one party is located. Propose: 'This Agreement shall be governed by the laws of [contractor's state/country]. Any litigation shall be conducted in the courts of [contractor's jurisdiction], or by mutual agreement, via remote arbitration.'"

---

### Y12: Indefinite Survival Clauses

- **Category**: Confidentiality Risk
- **Detection phrases**: "the following sections shall survive termination indefinitely", "survival of obligations without expiration", "Sections [X, Y, Z] shall survive in perpetuity"
- **Example clause**: "Sections 5 (Confidentiality), 7 (Indemnification), 9 (Limitation of Liability), and 11 (Non-Compete) shall survive the termination or expiration of this Agreement indefinitely."
- **Why it's risky**: Bundling multiple obligations into an indefinite survival clause means the contractor is bound by indemnification, non-compete, and confidentiality obligations forever. While some survival is standard (especially for confidentiality), indefinite survival of indemnification and non-compete clauses creates open-ended exposure.
- **Mitigation**: "Set specific survival periods per section. Propose: 'Confidentiality: 3 years. Indemnification: 2 years. Limitation of Liability: 2 years. Non-Compete: per the non-compete duration specified in Section [X]. All other obligations terminate upon contract expiration or termination.'"

---

## Green (Low Risk) Patterns

Green patterns represent standard, balanced clauses. Flag these as Green to confirm the contract includes proper protections. Green classifications reassure the user that these clauses are within normal range.

---

### G01: Standard Auto-Renewal With 30-Day Notice

- **Category**: Termination Risk
- **Detection phrases**: "automatically renew for successive [period] terms unless either party provides at least thirty (30) days' written notice"
- **Example clause**: "This Agreement shall automatically renew for successive one-year terms unless either party provides at least thirty (30) days' written notice of non-renewal prior to the end of the then-current term."
- **Why it's standard**: Clear renewal mechanism with a reasonable notice window that gives both parties adequate time to plan.

---

### G02: Mutual Indemnification

- **Category**: Liability Risk
- **Detection phrases**: "each party shall indemnify the other", "mutual indemnification", "each party agrees to indemnify, defend, and hold harmless the other party"
- **Example clause**: "Each party shall indemnify, defend, and hold harmless the other party from and against any claims, damages, and expenses arising from the indemnifying party's breach of this Agreement or negligent acts."
- **Why it's standard**: Both parties share risk equally. Neither party bears a disproportionate burden. This is the industry standard for balanced contracts.

---

### G03: Boilerplate Warranty Disclaimers

- **Category**: Liability Risk
- **Detection phrases**: "AS IS", "WITHOUT WARRANTY OF ANY KIND", "DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED", "NO WARRANTY OF MERCHANTABILITY OR FITNESS"
- **Example clause**: "EXCEPT AS EXPRESSLY SET FORTH IN THIS AGREEMENT, THE SERVICES ARE PROVIDED 'AS IS' WITHOUT WARRANTY OF ANY KIND. CONTRACTOR DISCLAIMS ALL WARRANTIES, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE."
- **Why it's standard**: Standard warranty disclaimer that limits exposure to implied warranties. Combined with the express warranty of professional and workmanlike performance, this is a balanced approach.

---

### G04: Standard Confidentiality (2-3 Year Survival)

- **Category**: Confidentiality Risk
- **Detection phrases**: "confidentiality obligations shall survive for a period of two (2) years" OR "three (3) years", "following the termination or expiration", combined with carve-outs for public information
- **Example clause**: "The obligations of confidentiality shall survive for a period of three (3) years following the termination of this Agreement. Confidential Information does not include information that: (a) is or becomes publicly available; (b) was known to the receiving party prior to disclosure; (c) is independently developed; or (d) is received from a third party without restriction."
- **Why it's standard**: Time-limited confidentiality with standard carve-outs is the industry norm. Three years provides adequate protection for most business information without creating indefinite obligations.

---

### G05: Clear Payment Terms (Net-30 or Net-45)

- **Category**: Payment Risk
- **Detection phrases**: "within thirty (30) days of invoice", "Net-30", "within forty-five (45) days of invoice", "Net-45", combined with late payment provisions
- **Example clause**: "Client shall pay each invoice within thirty (30) days of receipt. Late payments shall accrue interest at the rate of 1.5% per month. Contractor may suspend work if any invoice remains unpaid for more than fifteen (15) days past the due date."
- **Why it's standard**: Specific payment window, late payment consequences, and work suspension right create a balanced and enforceable payment structure.

---

### G06: Balanced Termination (Both Parties, With Notice)

- **Category**: Termination Risk
- **Detection phrases**: "either party may terminate with [N] days' written notice", "upon thirty (30) days' prior written notice", "mutual termination rights", combined with payment for completed work
- **Example clause**: "Either party may terminate this Agreement for convenience upon thirty (30) days' written notice. Upon termination, Client shall pay Contractor for all services performed through the effective date of termination."
- **Why it's standard**: Mutual termination rights with a notice period and payment for completed work protect both parties fairly.

---

### G07: Standard IP Ownership (Client Owns Deliverables, Contractor Retains Pre-Existing)

- **Category**: IP Risk
- **Detection phrases**: "Client shall own all Deliverables", "Contractor retains all pre-existing intellectual property", "license to pre-existing IP", combined with a pre-existing IP schedule or carve-out
- **Example clause**: "Upon full payment, Client shall own all Deliverables created specifically for Client under this Agreement. Contractor retains all right, title, and interest in pre-existing intellectual property, tools, and methodologies. Client is granted a non-exclusive, perpetual license to use Contractor's pre-existing IP solely as embedded in the Deliverables."
- **Why it's standard**: Clean separation between project-specific deliverables (client owns) and the contractor's professional toolkit (contractor retains). The license-back ensures the deliverables are usable without granting unnecessary ownership.

---

### G08: Reasonable Non-Compete (Under 1 Year, Narrow Scope)

- **Category**: Non-Compete Risk
- **Detection phrases**: "for a period of six (6) months" OR "twelve (12) months", "shall not provide substantially similar services to [named competitors]", narrow geographic or industry scope
- **Example clause**: "For a period of six (6) months following termination, Contractor shall not provide substantially similar services to the companies listed in Exhibit B. This restriction is limited to direct competitors of Client in the [specific industry] market within [specific geographic area]."
- **Why it's standard**: Short duration, named competitors (rather than broad industry definitions), and narrow geographic scope create a restriction that protects the client's legitimate interests without crippling the contractor's livelihood.
