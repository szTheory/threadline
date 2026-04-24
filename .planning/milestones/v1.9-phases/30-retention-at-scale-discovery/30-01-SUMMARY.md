---
phase: 30-retention-at-scale-discovery
plan: "01"
subsystem: docs
tags: [retention, purge, production-checklist, scale]

requires: []
provides:
  - "§4 volume H3 tied to Threadline.Retention.Policy, purge/1, mix threadline.retention.purge"
  - "§5 export bullet linking retention windows to filters and domain-reference export anchor"
  - "Support incident intro sentence with in-file link to §4"
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - guides/production-checklist.md

key-decisions:
  - "Followed 30-CONTEXT D-1–D-3 placement and API literals from lib sources."

patterns-established: []

requirements-completed: [SCALE-01]

duration: 25min
completed: 2026-04-24
---

# Phase 30 plan 30-01 summary

**Production checklist now ties volume, purge cadence, and monitoring to shipped retention APIs and links export/support readers back to §4.**

## Performance

- **Tasks:** 3
- **Files modified:** 1

## Accomplishments

- Added **`### Volume, growth, and purge cadence`** under **`## 4. Retention and purge`** with `Threadline.Retention.Policy`, **`Threadline.Retention.purge/1`** (`repo:` required, `{:error, :disabled}`), **`mix threadline.retention.purge`** dry-run vs prod `--execute`, batch defaults, monitoring, and link to **`domain-reference.md#retention-phase-13`**.
- Extended **`## 5. Export and investigation`** with retention vs `:from`/`:to`, `max_rows`, `stream_changes/2`, correlation, and **`domain-reference.md#export-phase-14`**.
- Added support intro sentence with **`#4-retention-and-purge`** anchor.

## Task commits

Single commit groups all checklist edits (file is one artifact).

## Files created/modified

- `guides/production-checklist.md`

## Decisions made

None — executed plan as written.

## Deviations from plan

None.

## Issues encountered

- **`mix test`** could not run: `test_helper.exs` requires PostgreSQL database `threadline_test` (role `postgres`); environment had no reachable instance. **`mix compile --warnings-as-errors`** passed; plan acceptance greps passed.

## Next phase readiness

Plan **30-02** can add the domain-reference hub and README pointer; deep-link to **`production-checklist.md#4-retention-and-purge`** is valid.

## Self-Check: PASSED

- Acceptance greps from **30-01-PLAN.md** all exit 0.
- `mix compile --warnings-as-errors`: PASS.
- `mix test`: not executed (DB unavailable); doc-only change.

---
*Phase: 30-retention-at-scale-discovery · Plan: 30-01*
