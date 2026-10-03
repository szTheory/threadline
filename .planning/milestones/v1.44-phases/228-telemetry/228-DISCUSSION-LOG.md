# Phase 228: Telemetry - Discussion Log

**Date:** 2026-10-01
**Mode:** research-then-recommend (maintainer: "auto follow ur recs")

> Human reference only; downstream agents read 228-CONTEXT.md.

## Research dispatched (parallel advisor researchers)

| Area | Recommendation adopted | Decisions |
|------|------------------------|-----------|
| A. Export emission | Emit at unit-of-work owners (eager fns, Orchestrator.run, chunked controller path); no message strings; native duration | D-04..D-07 |
| B. Retention span | Span after input checks; counts in measurements; per-step batch_purged after commit; dry run emits no batches | D-08..D-11 |
| C. Contract and docs | Internal registry + runtime allowlist + static scan + doc parity; PROP-04 telemetry surface; guide outline | D-01..D-03, D-12..D-16 |

## Maintainer question (HIGH-IMPACT, breaking public telemetry)

**Q:** Existing events break TELE-03 (actor_ref fields on 3 undocumented operator-surface events; message string on health.checked.error). How to handle?

| Option | Selected |
|--------|----------|
| Strip now (Recommended): remove actor ids, swap message for exception module, CHANGELOG Breaking changes for 0.12.0 | ✓ |
| Narrow TELE-03 to new events only | |
| Deprecate first, remove in v1.45 | |

Recorded as D-17 (one-way).

## Claude's discretion
Helper names, registry structure, table parsing, auth-event fixtures, error_kind subset.

## Deferred
Public events/0; atom measurements to metadata (v1.45); purge :disabled event; export surface metadata; stream-primitive events; stuck "running" retention row.
