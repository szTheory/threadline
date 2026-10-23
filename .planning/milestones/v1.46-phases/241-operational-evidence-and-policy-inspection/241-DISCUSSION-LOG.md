# Phase 241: Operational evidence and policy inspection - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-10
**Phase:** 241-operational-evidence-and-policy-inspection
**Areas discussed:** Schema-scoped coverage and remediation; evidence projection and proof limits; configured-versus-deployed redaction

---

## Schema-scoped coverage and remediation

| Option | Description | Selected |
|--------|-------------|----------|
| Selected-schema triage with safe schema-qualified host-migration guidance | Keeps URL, table identity, gap and remediation tied to the requested schema; safe commands can be generated only for conservative identifiers. | ✓ |
| All-schema grouped overview with drilldown | Surfaces cross-schema gaps at once, but adds catalog breadth, more rows and tenant/scope exposure. | |
| Selected-schema detail with documentation-only remediation | Keeps the display simple but adds identifier lookup and transcription work. | |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected the research-backed selected-schema approach.
**Notes:** Coverage unknown, stale, empty, expected-gap, uncovered and covered states must remain distinct. Host-owned migrations are never applied by the UI.

---

## Evidence projection and proof limits

| Option | Description | Selected |
|--------|-------------|----------|
| Extend latest projection → per-reference history with explicit assessment and limits | Reuses current reads and route; states what is recorded, unavailable, inferred, unsupported, or outside the evidence claim. | ✓ |
| One chronological evidence ledger with filters | Makes time bounds visible but combines different subject families and makes latest state less distinct. | |
| A new subject-proof dossier | Puts claim scope first, but adds a new presentation model and risk of exposing arbitrary host details. | |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected the existing latest/history model with explicit availability and completeness wording.
**Notes:** “No record for this selection” does not mean “no activity.” A failed read must not be shown as an empty result. A proof status applies to its recorded snapshot and does not establish full capture coverage.

---

## Configured-versus-deployed redaction

| Option | Description | Selected |
|--------|-------------|----------|
| Per-table normalized comparison with match, drift, and unverified states | Shows actionable configured/deployed differences; corrects the empty-policy/missing-trigger false match and protects values. | ✓ |
| Drift-first view with matching detail collapsed | Reduces scanning but risks making matching state appear absent. | |
| Status or fingerprint only | Minimizes displayed policy metadata but does not show what differs or how to fix it. | |

**User's choice:** `[--auto]` The maintainer authorized auto-following recommendations; selected the per-table normalized comparison.
**Notes:** Keep the three documented public status values. A configured table with a known missing trigger is `drift_detected` even when the policy is empty; reserve `could_not_introspect` for an existing trigger that cannot be safely interpreted. Never expose raw SQL or redacted sample values.

---

## the agent's Discretion

- Choose exact concise copy, grouping and order, responsive presentation, and minimal tests within locked scope.
- Keep sensitive canaries out of rendered HTML, report output, and copy payloads; verify actual clipboard content if a control is added.
- Use existing named verification entrypoints and prove the tests are discovered by CI.

## Deferred Ideas

- All-schema inventory, new health queries, evidence API/status/pagination changes, generic raw host detail rendering, automatic migration application, and expanded policy management.
- Phase 242 export/retention operations and Phase 243 integrated review.
