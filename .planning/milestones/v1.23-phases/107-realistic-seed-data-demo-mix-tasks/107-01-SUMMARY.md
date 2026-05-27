---
phase: 107-realistic-seed-data-demo-mix-tasks
plan: 01
subsystem: testing
tags: [elixir, phoenix, demo-seed, manifest, uuid-v5]

requires:
  - phase: 106-sigra-auth-lane-in-reference-app
    provides: Sigra users, provision_default_workspace_for_user, password123456 fixture convention
provides:
  - ThreadlinePhoenix.Demo.Manifest accessors for frozen walkthrough literals
  - DEMO-MANIFEST.md and DEMO_USERS.md human-readable contracts
  - dev.exs demo_epoch and demo_seed_password config keys
affects:
  - 107-02 reset/delete
  - 107-03 seed runner
  - 108 walkthrough scripting

tech-stack:
  added: []
  patterns:
    - "UUID v5 under threadline.demo namespace for stable org/user ids"
    - "Manifest module attributes as compile-time SSOT; docs mirror literals"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
    - examples/threadline_phoenix/DEMO-MANIFEST.md
    - examples/threadline_phoenix/DEMO_USERS.md
    - examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs
  modified:
    - examples/threadline_phoenix/config/dev.exs

key-decisions:
  - "Nested Manifest.UUID module for compile-time v5 derivation (parent module attributes cannot call sibling defs)"
  - "Third org slug globex for WALK-02 non-Acme samples"
  - "demo_last_tuesday fixed at 2026-05-20T14:30:00Z (seven days before demo_epoch)"

patterns-established:
  - "Pattern: DEMO-MANIFEST.md + Demo.Manifest stay in sync; Phase 108 copies prose from manifest docs"

requirements-completed: []

duration: 15min
completed: 2026-05-27
---

# Phase 107 Plan 01: Demo Manifest Contract Summary

**Frozen demo manifest with UUID v5 org/user ids, hero tickets 4521/4518, temporal anchors, and dev/test credential docs before any seed writes.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-27T17:30:00Z
- **Completed:** 2026-05-27T17:45:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- `ThreadlinePhoenix.Demo.Manifest` exposes `epoch/0`, `last_tuesday/0`, `org_id/1`, hero ticket numbers, user emails/ids, correlation and evidence run ids, and `demo_seed_password/0` (env-aware).
- `DEMO-MANIFEST.md` and `DEMO_USERS.md` document literals and dev/test-only credentials with cross-links.
- `config/dev.exs` sets `:demo_epoch` and `:demo_seed_password`; smoke tests lock Acme org UUID stability.

## Task Commits

Each task was committed atomically:

1. **Task 1: ThreadlinePhoenix.Demo.Manifest module** - `a073b97` (feat)
2. **Task 2: DEMO-MANIFEST.md and DEMO_USERS.md** - `7242a36` (docs)
3. **Task 3: Dev config keys + manifest smoke test** - `59eab15` (test)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex` - Programmatic manifest accessors and UUID v5 helper
- `examples/threadline_phoenix/DEMO-MANIFEST.md` - Walkthrough literal tables for Phase 108
- `examples/threadline_phoenix/DEMO_USERS.md` - Public demo credentials (dev/test banner)
- `examples/threadline_phoenix/config/dev.exs` - `demo_epoch` and `demo_seed_password` keys
- `examples/threadline_phoenix/test/threadline_phoenix/demo_manifest_test.exs` - Manifest contract smoke tests

## Decisions Made

- Used nested `Manifest.UUID` so compile-time module attributes can derive v5 ids (Elixir cannot call same-module `def` from `@attribute`).
- Chose `globex` as third org slug per planner discretion in CONTEXT.
- Test setup uses `Application.put_env` for demo keys so tests pass without duplicating config in `test.exs`.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Ready for **107-02** (`delete_reply/3`, `demo.reset`, `@demo_tables`).
- Manifest literals are stable for seed upserts and Phase 108 `WALKTHROUGH.md` imports.
- **SEED-03** remains open until `mix demo.seed` plants hero rows (plans 107-03/04); this plan delivered the manifest contract only.

## Self-Check: PASSED

- `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_manifest_test.exs` — 5 tests, 0 failures
- `mix compile --warnings-as-errors` — success
- No files under `lib/threadline/` modified

---
*Phase: 107-realistic-seed-data-demo-mix-tasks*
*Completed: 2026-05-27*
