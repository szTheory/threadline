# Phase 232: Consolidated Reads, Deprecations and the Bounded Default - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-10-03
**Phase:** 232-consolidated-reads-deprecations-and-the-bounded-default
**Areas discussed:** row_history element type, Page/cursor rules, filter-fold scope and retired names, truncation telemetry and doc hiding

Mode: advisor (minimal_decisive). Four gsd-advisor-researcher agents ran in parallel before the first question. The orchestrator then reconciled their findings into one set:
- It overrode the filters researcher, who wanted to keep `actor_window_page`/`correlation_bundle_page`/`row_history_page`. SC3's paired-name test forbids that.
- It overrode the telemetry researcher, who treated `length == limit` as locked. Only "fires when the cap is hit" is maintainer-locked.

---

## row_history/3 element type (HIGH-IMPACT)

| Option | Description | Selected |
|--------|-------------|----------|
| LinkedChange | Change + transaction + action. Matches row_history/4, actor_window and correlation_bundle. No 0.12 call breaks without a warning. history/3's delegate keeps returning AuditChange. | ✓ |
| Plain AuditChange | Lean, matches timeline/2. Short-arity row_history calls break at runtime with no compiler warning. | |

**User's choice:** LinkedChange (Recommended)

## actor_history/2 paging (HIGH-IMPACT)

| Option | Description | Selected |
|--------|-------------|----------|
| Always paged, unified opts | Returns a Page; `cursor:` (`:start`/map/`{:before, map}`) and `page_size:`; legacy `:after`/`:before`/`:limit` warn at runtime until 2.0 | ✓ |
| Follow the row_history rule | Bare capped list by default, Page only with `cursor:`; scope growth | |
| Keep current opts | Only the struct changes; leaves two cursor vocabularies at 1.0 | |

**User's choice:** Always paged, unified opts (Recommended)

## Rest of the set (Page/cursor, retired names, telemetry, hiding)

| Option | Description | Selected |
|--------|-------------|----------|
| Accept all | Lock items 1–4 as recommended | ✓ |
| Adjust specific picks | — | |

**User's choice:** Accept all (Recommended)

## Claude's Discretion

- Internal module layout for hidden raw-read and legacy helpers
- Deprecation warning text and the runtime-warning mechanism for legacy actor_history options
- Plan/wave split and test file names

## Deferred Ideas

- Note in the stability guide the reliance on old filter keys staying valid as opts (Phase 235)
- Removing deprecated names and legacy options (2.0)
- Moving filters into the options list for timeline/export/actor_window/correlation_bundle (not done for 1.0)
