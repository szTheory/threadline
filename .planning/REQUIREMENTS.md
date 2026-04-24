# Requirements: Threadline — v1.8

**Defined:** 2026-04-24  
**Milestone:** v1.8 — Close the support loop  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## Evidence-driving questions (canonical SaaS support)

These five questions anchor scope. Each maps to at least one REQ-ID below; implementation may use **`Threadline.Query` / `Threadline.Export`**, top-level delegators, or **documented SQL** where the library intentionally stays thin.

1. **Row history** — “What changed for this domain row (PK) in the last N days?”
2. **Actor window** — “What did this actor drive across tables in a time window?”
3. **Correlation bundle** — “What row-level changes and semantic actions share this `correlation_id` / request trace?”
4. **Export parity** — “Can I export the same slice I use for incident review (not a different filter vocabulary)?”
5. **Action ↔ capture** — “How do I tie a semantic action to the captured mutations in one place?”

---

## v1.8 requirements

### Support loop — timeline, export, correlation

- [x] **LOOP-01**: **`Threadline.Query.timeline/2`**, **`timeline_query/1`**, **`export_changes_query/1`**, and **`Threadline.Export`** paths accept an optional **`:correlation_id`** filter (string). When set, results include only `audit_changes` whose joined `audit_transactions` link to an **`audit_actions`** row with that `correlation_id` (via `action_id`). When `correlation_id` is absent, behavior matches today. **`validate_timeline_filters!/1`** and **`CHANGELOG.md`** document the new key; integration tests prove timeline + CSV/JSON export agree on the same filter list.

- [x] **LOOP-02**: **`guides/domain-reference.md`** and **`guides/production-checklist.md`** gain a **Support incident queries** subsection that answers questions **1–5** with a small table: question → **API / Mix task** vs **copy-paste SQL** (with pointers to `AuditChange`, `AuditTransaction`, `AuditAction` columns). Text stays SQL-native; no LiveView.

- [ ] **LOOP-03**: **`examples/threadline_phoenix/`** demonstrates **one** end-to-end correlation path: HTTP request with **`x-correlation-id`**, audited write + optional **`record_action/2`** with correlation, and a **test or README snippet** showing retrieval via **`Threadline.timeline/2`** or export using **`:correlation_id`** after LOOP-01 ships.

- [x] **LOOP-04**: A **doc contract test** asserts stable anchor strings (or headings) from LOOP-02 exist so support sections do not rot. Prefer extending an existing doc-contract test module if the project already groups guide contracts; otherwise add a focused test under **`test/threadline/`**.

---

## Future (after v1.8)

_Defer unless a later milestone explicitly reopens._

- **Additional timeline dimensions** — e.g. `request_id` / `job_id` filters on actions or transactions, multi-column “support dashboards,” without a pilot-backed REQ.
- **LiveView operator UI** — remains out of scope per **`PROJECT.md`**.
- **`threadline_web` / umbrella** — packaging leap; defer until public query/export surface stabilizes.

---

## Out of scope (v1.8)

| Item | Reason |
|------|--------|
| LiveView operator UI | Explicit product deferral |
| Published `threadline_web` companion | Packaging milestone, not support-loop |
| New capture / redaction / retention semantics | Exploration milestone only |
| Maintainer attestation of third-party STG URLs | Unchanged integrator-owned policy |

---

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| LOOP-01 | Phase 25 | Complete |
| LOOP-02 | Phase 26 | Complete |
| LOOP-03 | Phase 27 | Pending |
| LOOP-04 | Phase 26 | Complete |

**Coverage:** v1.8 requirements: **4** total — mapped: **4** — unmapped: **0** ✓

---

*Requirements defined: 2026-04-24 — milestone v1.8 (SaaS trajectory chunk 1)*
