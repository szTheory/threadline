---
phase: 30-retention-at-scale-discovery
plan: "02"
subsystem: docs
tags: [domain-reference, readme, discovery, scale]

requires:
  - phase: 30-01
    provides: "Stable §4 volume H3 and production-checklist anchors"
provides:
  - "Operating at scale (v1.9+) hub in domain-reference with stable id operating-at-scale-v19"
  - "README Maintainer-band paragraph linking to hub"
affects: []

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified:
    - guides/domain-reference.md
    - README.md

key-decisions:
  - "Used explicit HTML id operating-at-scale-v19 for stable README fragment."

patterns-established: []

requirements-completed: [SCALE-02]

duration: 15min
completed: 2026-04-24
---

# Phase 30 plan 30-02 summary

**Domain reference gains a v1.9 at-scale map (links only), and README routes operators there from Maintainer checks.**

## Performance

- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Inserted **`## Operating at scale (v1.9+)`** after the audit indexing section with bullets to telemetry, trigger coverage, **`audit-indexing.md`**, and **`production-checklist.md#4-retention-and-purge`**.
- Added README paragraph under **`## Maintainer checks`** linking **`guides/domain-reference.md#operating-at-scale-v19`** without removing **`### Data retention and purge`**.

## Task commits

Single commit covers hub + README.

## Files created/modified

- `guides/domain-reference.md`
- `README.md`

## Decisions made

- Chose explicit `<span id="operating-at-scale-v19">` before the H2 so README anchor matches plan acceptance (`#operating-at-scale-v19`).

## Deviations from plan

None.

## Issues encountered

- Same as 30-01: full **`mix test`** not run (PostgreSQL unavailable in executor environment). **`mix compile --warnings-as-errors`** passed; plan acceptance greps passed.

## Self-Check: PASSED

- Acceptance greps from **30-02-PLAN.md** all exit 0.
- `mix compile --warnings-as-errors`: PASS.

---
*Phase: 30-retention-at-scale-discovery · Plan: 30-02*
