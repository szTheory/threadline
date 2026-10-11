---
phase: 241
reviewed: 2026-10-10
depth: standard
files_reviewed: 23
findings:
  critical: 0
  warning: 2
  info: 0
  total: 2
status: issues_found
reviewer: Codex inline
---

# Phase 241: Code Review

Reviewed the 23 source/test paths changed from phase entry `888e429a`, including inherited Plans 01/02 and recovered Plans 03/04. Review was performed inline; no independent subagent pass is claimed. The task-commit scope was reconciled to include the original Wave 1 contract follow-up `cc5aa141`.

## Findings

### WR-01: Policy refresh must honor disabled access and invalid schema state

The recovered refresh handler originally queried policy even when policy was disabled or schema validation had failed. A forged LiveView event could bypass the rendered control's availability. The recovery regression observed a report change where an unchanged socket was required.

Fixed in `5d7c81a2`: the server handler requires enabled policy and no schema error; all other refresh events are inert. `refresh ignores disabled policy access and an invalid selected schema` passes. The later retry handler also revalidates the selected schema.

### WR-02: Policy inspection outages must clear prior assurance and hide raw errors

Schema enumeration/validation converted connection errors into visible exception text, and a catalog read during refresh raised rather than returning an unavailable comparison. Two new tests reproduced both failures before implementation.

Fixed in `3bbe19eb`: narrow `DBConnection.ConnectionError` handling returns a schema-scoped unavailable state, clears report/sections, retains refresh, and retries enumeration/validation/catalog inspection. Tests exercise all three boundaries, continued failure, successful recovery, and a failed refresh after a successful comparison. Private error canary text never reaches HTML. The final focused presenter/LiveView suite passed 31 tests.

## Other Boundaries Reviewed

- Coverage read failure, confirmed-empty and stale last-good timestamps remain distinct. Schema and table identifiers both pass the conservative generator-safe check before shell command generation; unsafe exact names remain display-only with manual migration guidance.
- Evidence read failure is caught only at the connection boundary, distinct from no-match and disabled access. Fixed `Proof.present_record/1` projection excludes arbitrary host detail/provenance. Subject/reference serialization and history scope remain exact.
- Redaction catalog source remains inside the parser. Missing trigger, existing unreadable trigger and successfully matched policy remain the three documented statuses. All-clear requires at least one inspected match and no drift/unreadable rows.
- Browser mutation fixtures require the E2E flag and a numeric runner-owned test partition; temporary trigger/function changes are restored in `finally`. Production inspection remains read-only.
- Browser cases wait for LiveView connection, assert normalized DOM/attributes, exercise native disclosure and preserve complete references. Real zoom uses Chrome tab readback, and the desktop-only capability is explicitly skipped on mobile.
- Control inventories preserve existing IDs and independently discovered declarations. No dependency, lockfile, public API, capture trigger contract or baseline changes were introduced.

## Validation

Final canonical CI evidence is recorded in `241-CI-RECEIPT.json` and `241-VERIFICATION.md`. UI spacing/copy advisories are dispositioned in `241-UI-REVIEW.md`; they do not reopen the two repaired behavior defects above.
