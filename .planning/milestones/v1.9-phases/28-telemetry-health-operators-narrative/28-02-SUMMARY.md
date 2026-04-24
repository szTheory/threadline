---
phase: 28-telemetry-health-operators-narrative
plan: 02
subsystem: docs
tags: [checklist, readme, operators]

requires:
  - phase: 28-01
    provides: domain-reference telemetry + trigger coverage anchors
provides:
  - production-checklist cross-links aligned with domain reference
  - README pointer to trigger-coverage-operational anchor
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - guides/production-checklist.md
    - README.md

key-decisions:
  - "README gains explicit guides/domain-reference.md#trigger-coverage-operational link near verify_coverage prose."

patterns-established: []

requirements-completed: [OPS-01, OPS-02]

duration: 15min
completed: 2026-04-24
---

# Phase 28 — Plan 02 summary

**Production checklist and README** now steer operators to the same trigger-coverage and telemetry anchors as `guides/domain-reference.md`, without duplicating full policy prose.

## Performance

- **Tasks:** 2
- **Files touched:** 2

## Accomplishments

- **§1 Capture and triggers:** cadence for `Threadline.Health.trigger_coverage/1`, tuple meaning, `expected_tables` CI gate, audit catalog exclusions — all with `domain-reference.md#trigger-coverage-operational`.
- **§6 Observability:** telemetry bullet also links trigger coverage anchor.
- **README:** one sentence linking `guides/domain-reference.md#trigger-coverage-operational` next to maintainer verify_coverage guidance.

## Task commits

1. **28-02-01 + 28-02-02** — checklist §1/§6 + README discovery line — `7a83809`

## Verification

- `mix format`
- `mix compile --warnings-as-errors`
- `DB_PORT=5433 MIX_ENV=test mix test`

## Self-Check: PASSED

- Plan **`28-02-PLAN.md`** acceptance greps satisfied.
