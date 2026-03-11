# Integration Test Plan: Invoice Processor

## Test Scenarios

### Scenario 1: Single Invoice — Native PDF (Default Mode)

**Command**: `/invoice:process /test-data/native-invoice.pdf`

**Setup**: A native PDF (text layer) with complete invoice data.

**Expected**:
- Extraction confidence ≥ 0.85
- All required fields extracted: vendor, invoice_number, invoice_date, total
- Line items present and math-correct
- Expense category assigned with confidence ≥ 0.7
- Output formatted markdown summary to user
- No Notion write

**Acceptance Criterion 1**: `/invoice:process [file]` extracts single invoice ✓

---

### Scenario 2: Single Invoice — Scanned Image (Default Mode)

**Command**: `/invoice:process /test-data/scanned-invoice.jpg`

**Setup**: A JPG photograph of a printed invoice.

**Expected**:
- Extraction confidence between 0.5–0.85 (OCR quality)
- Vendor name and total extracted (critical fields)
- Dates in ISO 8601 format
- Output formatted summary to user

**Acceptance Criterion 3**: Extracts vendor, amount, date, line items ✓

---

### Scenario 3: Folder Batch — Default Mode

**Command**: `/invoice:batch /test-data/invoices/`

**Setup**: Folder with 5 PDF invoices + 1 unsupported file (.xlsx)

**Expected**:
- 5 invoices processed
- 1 unsupported file silently skipped (no error)
- Summary table showing all 5 invoices with categories
- Total amount summed correctly
- No Notion writes

**Acceptance Criterion 2**: `/invoice:batch [folder]` processes multiple ✓

---

### Scenario 4: Full Pipeline — Auto-Approved Invoice

**Command**: `/invoice:process /test-data/known-vendor-invoice.pdf --team`

**Setup**: Invoice from a known vendor, amount < $5,000, valid data.

**Expected**:
- All 5 agents run sequentially
- Validation passes all checks
- Expense category assigned
- Approval status: `auto_approved`
- Notion record created in "Founder OS HQ - Finance" database with Type="Invoice" (or fallback "Invoice Processor - Invoices")
- Company relation set if vendor matches a Companies DB entry
- Notion URL returned to user

---

### Scenario 5: Full Pipeline — High Amount (Requires Approval)

**Command**: `/invoice:process /test-data/large-invoice.pdf --team`

**Setup**: Invoice with total > $5,000.

**Expected**:
- Approval status: `requires_approval`
- Notion approval request created in "Founder OS HQ - Finance" with Type="Approval" (or fallback "Invoice Processor - Approvals")
- Notion invoice record created in "Founder OS HQ - Finance" with Type="Invoice" and status "Pending Approval"
- User sees approval request URL

---

### Scenario 6: Full Pipeline — First-Time Vendor

**Command**: `/invoice:process /test-data/new-vendor-invoice.pdf --team`

**Setup**: Invoice from a vendor not previously seen.

**Expected**:
- Approval status: `needs_review`
- Notion approval request created in "Founder OS HQ - Finance" with Type="Approval"
- Invoice recorded in "Founder OS HQ - Finance" with Type="Invoice" and "Needs Review" status

---

### Scenario 7: Anomaly Detection — Duplicate Invoice

**Command**: Process the same invoice twice with `--team`

**Setup**: Run `/invoice:process` on the same file twice.

**Expected**:
- Second run: approval status `rejected` (duplicate detected)
- Second Notion record created in "Founder OS HQ - Finance" with Type="Invoice", "Rejected" status and reason
- Batch does NOT double-count the amount

**Acceptance Criterion 6**: Flags duplicates and anomalies ✓

---

### Scenario 8: Year-End Batch with Agent Teams

**Command**: `/invoice:batch /test-data/year-invoices/ --team`

**Setup**: 20+ invoice files simulating a year of invoices.

**Expected**:
- Up to 5 concurrent pipelines running
- Progress reported every 5 items
- All invoices recorded in "Founder OS HQ - Finance" with Type="Invoice"
- Failed/error items reported in summary
- Batch summary shows category breakdown and total amount

**Acceptance Criterion 5**: Agent Teams process year's invoices in one run ✓

---

### Scenario 9: Date Filtering

**Command**: `/invoice:batch /test-data/mixed-dates/ --since=2024-07-01 --team`

**Setup**: Folder with invoices dated throughout 2024.

**Expected**:
- Only invoices with file modification date ≥ 2024-07-01 processed
- Earlier-dated files skipped
- Progress shows filtered count

---

### Scenario 10: Expense Categorization — 14 Categories

**Command**: `/invoice:batch /test-data/mixed-vendors/`

**Setup**: Invoices from vendors covering all 14 expense categories.

**Expected**:
- Each invoice categorized into correct category
- Tax-deductibility set correctly (meals = 50%, travel = partial)
- Budget codes assigned
- `other` category used only for truly ambiguous invoices

**Acceptance Criterion 4**: Auto-categorizes expenses ✓

---

### Scenario 11: Math Validation with Auto-Correction

**Command**: `/invoice:process /test-data/math-error-invoice.pdf --team`

**Setup**: Invoice where extracted total doesn't match subtotal + tax (minor OCR error).

**Expected**:
- Validation agent detects mismatch
- Auto-correction applied (recalculate from line items)
- `corrected_fields` populated in output
- Invoice NOT rejected due to auto-correction
- Notion record includes correction note

---

### Scenario 12: Unsupported Format

**Command**: `/invoice:process /test-data/invoice.docx`

**Expected**:
- Clear error message: "Unsupported format. Supported: PDF, JPG, JPEG, PNG, TIFF."
- No pipeline run
- No Notion writes

---

## Acceptance Criteria Coverage

| Criterion | Test Scenario(s) |
|-----------|-----------------|
| 1. `/invoice:process [file]` extracts single invoice | Scenarios 1, 2 |
| 2. `/invoice:batch [folder]` processes multiple | Scenarios 3, 8, 9 |
| 3. Extracts vendor, amount, date, line items | Scenarios 1, 2 |
| 4. Auto-categorizes expenses | Scenarios 1, 2, 10 |
| 5. Agent Teams: process year's invoices in one run | Scenario 8 |
| 6. Flags duplicates and anomalies | Scenarios 5, 6, 7 |
