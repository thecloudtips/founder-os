---
name: Invoice Extraction
description: "Extracts structured data from invoice files in PDF, JPG, PNG, and TIFF formats. Activates when the user has an invoice to process, wants to read an invoice PDF, parse billing documents, or asks 'what does this invoice say?' Handles OCR processing, field extraction, confidence scoring, and multi-format detection."
version: 1.0.0
---

# Invoice Extraction

Extract structured data from invoice files (PDF, JPG, JPEG, PNG, TIFF). Used by the extraction-agent as step 1 of the 5-agent pipeline.

## Target Database

Extracted data is ultimately recorded in the consolidated Finance database with `Type = "Invoice"`. DB discovery order: **"[FOS] Finance"** first, then "Founder OS HQ - Finance", then "Invoice Processor - Invoices" as legacy fallback. The vendor name is matched against the **Companies** database to populate a Company relation.

## Supported Formats

| Format | Notes |
|--------|-------|
| PDF (native) | Text layer available — high confidence |
| PDF (scanned) | Requires OCR — moderate confidence |
| JPG / JPEG | Photograph of invoice — apply OCR |
| PNG | Screenshot or scan — apply OCR |
| TIFF | High-resolution scan — apply OCR |

Reject unsupported formats with `error: "unsupported_format"`. Never attempt to process ZIP, DOCX, or spreadsheet files.

## Output Schema

All extracted data must conform to this structure:

```json
{
  "vendor": {
    "name": "string (required)",
    "address": "string or null",
    "tax_id": "string or null"
  },
  "invoice_number": "string or null",
  "invoice_date": "ISO 8601 date (required)",
  "due_date": "ISO 8601 date or null",
  "currency": "ISO 4217 code (default: USD)",
  "line_items": [
    {
      "description": "string",
      "quantity": "number",
      "unit_price": "number",
      "total": "number"
    }
  ],
  "subtotal": "number",
  "tax": "number",
  "total": "number (required)",
  "payment_terms": "string or null",
  "extraction_confidence": "number 0.0–1.0",
  "source_file": "string (original file path)"
}
```

## Field Extraction Rules

### Vendor
- Scan for company name at the top of the document (letterhead, logo area)
- Address: full street address including city, state/province, postal code
- Tax ID: look for EIN, VAT, GST, ABN, or similar identifier labels

### Invoice Metadata
- **Invoice number**: look for labels like "Invoice #", "Invoice No.", "Ref:", "Number:"
- **Invoice date**: look for "Date:", "Invoice Date:", "Issued:"; convert to ISO 8601 (YYYY-MM-DD)
- **Due date**: look for "Due:", "Payment Due:", "Pay By:"; may be calculated from payment terms
- **Currency**: default to USD if not stated; detect from "$", "€", "£", "¥" symbols or explicit labels

### Line Items
- Extract each line as a separate object
- **quantity**: default to 1 if not shown (services are often quantity 1)
- **unit_price**: price per unit before multiplication
- **total**: quantity × unit_price (verify or calculate)
- Descriptions may span multiple lines — join into a single string

### Financial Totals
- **subtotal**: sum before tax; may be labeled "Subtotal", "Net Amount"
- **tax**: total tax amount; may show multiple tax lines — sum them
- **total**: grand total due; may be labeled "Total Due", "Amount Due", "Balance Due"
- All monetary values must be **numbers**, not strings (remove currency symbols, commas)

### Payment Terms
- Look for "Net 30", "Net 60", "Due on Receipt", "2/10 Net 30"
- Return as a string exactly as written, or null if not found

## Confidence Scoring

Assign `extraction_confidence` on a 0.0–1.0 scale:

| Score | Meaning |
|-------|---------|
| 0.9–1.0 | Native PDF with clear text; all required fields found |
| 0.7–0.89 | Good OCR result; minor fields missing (address, tax ID) |
| 0.5–0.69 | Moderate confidence; some amounts or dates uncertain |
| 0.3–0.49 | Low confidence; scanned image with poor quality |
| < 0.3 | Very low; partial extraction only |

**Do not inflate confidence.** A score of 0.92 should mean the data is almost certainly correct, not merely plausible.

## OCR Processing

For scanned PDFs and image files:
1. Analyze the entire document layout first — identify header, line items table, totals section
2. Pay special attention to table boundaries when extracting line items
3. Numbers are the most error-prone OCR targets — double-check amounts against totals
4. Common OCR errors: `0` vs `O`, `1` vs `l`, `,` vs `.` in numbers
5. If the image is rotated or skewed, note this may affect extraction quality

## Edge Cases

### Low Confidence Extraction (< 0.5)
Return `status: "success"` with the partial data and the low confidence score. Do NOT return `status: "error"` — let downstream agents (validation) decide what to do. Flag which fields are uncertain.

### Partial Extraction
If vendor name and total are found but line items cannot be parsed:
- Return what was extracted
- Set confidence proportionally lower
- Leave `line_items: []` (empty array, not null)

### Multiple Tax Lines
Sum all tax amounts into a single `tax` field. Example: "State Tax $10 + Federal Tax $5" → `"tax": 15`.

### Multi-Page Invoices
Line items may span multiple pages. Ensure all pages are processed before compiling the line items array.

### Scanned vs Native PDF
Native PDFs have a text layer — prefer extracting text directly. Scanned PDFs appear as images embedded in a PDF container — apply OCR to the image content.

### Unsupported Format
Return immediately:
```json
{
  "status": "error",
  "error": "unsupported_format",
  "message": "File type not supported. Supported: PDF, JPG, JPEG, PNG, TIFF."
}
```

## Quality Criteria

- All monetary amounts must be **numbers**, not strings
- All dates must be **ISO 8601** (YYYY-MM-DD format)
- Line item totals must be mathematically consistent: `quantity × unit_price = total` (within rounding)
- `extraction_confidence` must honestly reflect the actual quality of extraction
- `source_file` must always be populated with the original file path
- An empty `line_items` array is valid (e.g., single-total invoices) — never return null for line_items
