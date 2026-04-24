# Requirements: Threadline

**Defined:** 2026-04-24  
**Milestone:** v1.9 — Production confidence at volume  
**Core value:** Every row mutation that matters is captured durably and linked to who did it and why — without the developer having to remember to opt in.

## v1.9 Requirements

### Operations — telemetry & health

- [x] **OPS-01**: **`guides/domain-reference.md`** (or a clearly linked subsection) gives an **operator narrative** for each shipped **`[:threadline, …]`** telemetry event: **when it fires**, **recommended measurements** (e.g. what to chart or log), and **what “bad” looks like** in plain language. The narrative stays aligned with **`Threadline.Telemetry`** (`[:threadline, :transaction, :committed]`, `[:threadline, :action, :recorded]`, `[:threadline, :health, :checked]`) and cross-links to **`guides/production-checklist.md`** where operators run weekly checks.

- [x] **OPS-02**: **`guides/production-checklist.md`** and **`guides/domain-reference.md`** describe **`Threadline.Health.trigger_coverage/1`** as an **operational check**: when to run it (e.g. after deploy or schema change), how to interpret `{:covered, _}` / `{:uncovered, _}` for user tables, relationship to **`mix threadline.verify_coverage`**, and that audit catalog tables are excluded by design. Text references existing behavior (no new health semantics required for this REQ).

### Performance — indexing

- [x] **IDX-01**: A **dedicated indexing guide** (new **`guides/audit-indexing.md`** or equivalent ExDoc extra) documents **recommended indexes** for **`audit_transactions`**, **`audit_changes`**, and **`audit_actions`** for workloads that match **`Threadline.Query.timeline/2`**, **`Threadline.Export`**, optional **`:correlation_id`** filtering, and **retention / purge** patterns. The guide calls out **tradeoffs** (write amplification, bloat) and **does not** mandate one-size-fits-all DDL — it explains choices integrators make on their own databases.

- [x] **IDX-02**: At least one **doc contract test** under **`test/threadline/`** locks stable anchor strings (headings or markers) from the indexing guide so the cookbook cannot silently rot.

### Operations — retention at scale

- [x] **SCALE-01**: **`guides/production-checklist.md`** gains explicit **volume / growth** guidance tied to shipped retention APIs: **`Threadline.Retention.Policy`**, **`Threadline.Retention.purge/1`**, **`mix threadline.retention.purge`** — including suggested **cadence thinking**, **what to monitor** (table growth, purge duration), and how this connects to **export** and **timeline** usage already documented for support.

- [x] **SCALE-02**: **README** and/or **`guides/domain-reference.md`** includes a **short discovery pointer** (one paragraph + link) to the at-scale / indexing / retention narrative so new readers find v1.9 material without spelunking.

## Future (after v1.9)

_Defer unless a later milestone explicitly reopens._

- **Additional telemetry events or dashboards** — beyond documenting what exists today.
- **Automated index recommendations from library code** — integrator-owned DDL remains the default.
- **LiveView operator UI** — remains out of scope per **`PROJECT.md`**.

## Out of scope (v1.9)

| Item | Reason |
|------|--------|
| LiveView operator UI | Explicit product deferral |
| Published `threadline_web` companion | Packaging milestone |
| New capture / redaction / retention **semantics** | v1.9 is narrative + indexing guidance on **existing** APIs |
| Maintainer attestation of third-party STG URLs | Unchanged integrator-owned policy |
| Hex semver bump | Separate release decision |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| OPS-01 | Phase 28 | Complete |
| OPS-02 | Phase 28 | Complete |
| IDX-01 | Phase 29 | Complete |
| IDX-02 | Phase 29 | Complete |
| SCALE-01 | Phase 30 | Complete |
| SCALE-02 | Phase 30 | Complete |

**Coverage:** v1.9 requirements: **6** total — mapped: **6** — unmapped: **0** ✓

---
*Requirements defined: 2026-04-24 — milestone v1.9*
