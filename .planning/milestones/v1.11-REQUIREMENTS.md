# Requirements: Threadline

**Defined:** 2026-04-24  
**Milestone:** v1.11 — Composable incident surface  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

**Planning KPI (this milestone):** **Integrator composition speed** — close the gap between shipped exploration primitives (`audit_changes_for_transaction/2`, `change_diff/2`) and a **copy-pasteable host pattern** (example JSON), rather than a Hex-only or as-of exploration bet.

## v1.11 Requirements

### Composition — example incident JSON

- [x] **COMP-01**: After a successful audited write via **`examples/threadline_phoenix`** **`POST /api/posts`**, the JSON response includes **`audit_transaction_id`** (UUID of the capture **`audit_transactions`** row for that request’s DB transaction) so clients can drill in without guessing joins.
- [x] **COMP-02**: **`GET /api/audit_transactions/:id/changes`** (UUID `:id`) returns **200** with a JSON body listing every **`AuditChange`** for that transaction via **`Threadline.audit_changes_for_transaction/2`** (or **`Threadline.Query`**) with **documented ordering** (same contract as the library); each listed change includes a **JSON-serializable** **`change_diff`** map from **`Threadline.change_diff/2`**.
- [x] **COMP-03**: **`guides/domain-reference.md`** links this pattern under **Exploration API routing** with stable anchor **`COMP-EXAMPLE-INCIDENT-JSON`**; **`examples/threadline_phoenix/README.md`** documents the two-step flow (create → drill-down); a **doc contract test** in **`test/threadline/`** locks **`COMP-EXAMPLE-INCIDENT-JSON`** (and CI exercises the HTTP path via **`mix verify.example`**).

## Future (after v1.11)

_Defer unless a later milestone explicitly reopens._

- **As-of** row reconstruction across arbitrary history (high complexity; listed post–v1.10 exploration future).
- **Automated** index or DDL recommendations from library code (integrator-owned DDL remains default).
- LiveView or other **hosted** operator UI.

## Out of scope (v1.11)

| Item | Reason |
|------|--------|
| LiveView operator UI | Explicit product deferral (`PROJECT.md`); composition milestone only. |
| Published **`threadline_web`** / umbrella split | Packaging deferral; example stays under **`examples/`**. |
| New capture / redaction / retention **semantics** or migrations | Milestone consumes existing capture; no trigger or schema behavior changes. |
| Maintainer attestation of third-party STG URLs | Unchanged integrator-owned policy. |
| Hex semver bump | Separate release milestone unless explicitly combined. |
| Authentication / authorization product in the example | Document “add your own auth” only; no security framework in scope. |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| COMP-01 | Phase 37 | Complete |
| COMP-02 | Phase 37 | Complete |
| COMP-03 | Phase 37 | Complete |

**Coverage:** v1.11 requirements: **3** total — mapped: **3** — unmapped: **0** ✓

---
*Requirements defined: 2026-04-24 — milestone v1.11*
