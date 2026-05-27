---
phase: 107-realistic-seed-data-demo-mix-tasks
plan: 03
subsystem: demo-ops
tags: [elixir, phoenix, demo-seed, audit-capture, personas, temporal-backfill]

requires:
  - phase: 107-realistic-seed-data-demo-mix-tasks
    plan: 02
    provides: delete_reply/3, mix demo.reset, Demo.Tables
provides:
  - mix demo.seed with hybrid activity synthesis (personas, anchors, filler, temporal)
  - ThreadlinePhoenix.Demo.Seed.* pipeline modules
  - Deterministic ~50 tickets/org with hero incidents #4521/#4518
affects:
  - 107-04 retention/evidence tail and contract tests
  - 108 WALKTHROUGH.md scripting

tech-stack:
  added: []
  patterns:
    - "Seed.Context map with timestamps registry for temporal backfill"
    - "Explicit org/membership upsert after manifest org pre-create (avoids provision slug collision)"
    - "Per-ticket Repo.transaction filler without record_action"

key-files:
  created:
    - examples/threadline_phoenix/lib/mix/tasks/demo.seed.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs

key-decisions:
  - "Use explicit OrgMembership/Agent inserts on pre-upserted manifest orgs instead of provision_default_workspace_for_user when org slug already exists"
  - "Temporal backfill via parameterized SQL with Ecto.UUID.dump! for binary_id audit rows"
  - "Extra filler agents (agent2–agent7) use UUID v5 under threadline.demo namespace"

patterns-established:
  - "Pattern: Demo.Seed.run/0 pipeline Personas → Anchors → Filler → Temporal with :rand.seed at start"

requirements-completed: [SEED-01, SEED-02, SEED-03, SEED-05]

duration: 45min
completed: 2026-05-27
---

# Phase 107 Plan 03: Demo Seed Runner Summary

**`mix demo.seed` plants deterministic three-org help-desk fiction with hero audit incidents, PRNG filler volume, and manifest-driven timeline backfill — `mix demo.reset` now reseeds end-to-end.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-05-27T17:10:00Z
- **Completed:** 2026-05-27T17:22:00Z
- **Tasks:** 5
- **Files modified:** 8

## Accomplishments

- `Mix.Tasks.Demo.Seed` and `ThreadlinePhoenix.Demo.Seed.run/0` orchestrate personas, anchors, filler, and temporal passes with prod guard and pinned PRNG.
- Sigra users/orgs upserted from `Demo.Manifest` (fixed UUIDs, confirmed accounts, ~5 agents per org).
- Anchor layer: #4521 close with masked internal note + correlation `walk-acme-4521-close`, #4518 hard-delete by distinct deleter, 12-tx leaving-agent window, Globex close sample.
- Filler layer: ~50 tickets per org in separate transactions (GUC + org meta, no `record_action`).
- Temporal layer: `occurred_at` / `captured_at` backfilled from manifest offsets (hero at `last_tuesday`, delete +2h).

## Task Commits

Each task was committed atomically:

1. **Task 1: Mix task + seed orchestrator** - `f1bc720` (feat)
2. **Task 2: Personas — Sigra users and orgs** - `fb87560` (feat)
3. **Task 3: Anchor incidents (#4521 close, #4518 delete)** - `b3a2d9d` (feat)
4. **Task 4: Filler tickets (~50 per org)** - `f9fc7df` (feat)
5. **Task 5: Temporal backfill** - `cb5c420` (feat)

## Files Created/Modified

- `examples/threadline_phoenix/lib/mix/tasks/demo.seed.ex` - Mix entrypoint with prod guard
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` - Pipeline orchestrator
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/support.ex` - GUC helpers, timestamp registry, audit context builder
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/personas.ex` - Org/user upserts and memberships
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/anchors.ex` - Hero incidents and leaving-agent window
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/filler.ex` - PRNG volume tickets
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/temporal.ex` - Audit timestamp backfill
- `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` - Expect manifest orgs after reset+seed

## Decisions Made

- Skipped `provision_default_workspace_for_user/2` for demo org attachment because manifest orgs are pre-inserted; explicit membership avoids unique slug conflicts.
- Delete transaction id resolved via audit_changes join (order by `occurred_at`) instead of extending `delete_reply/3` return value.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `provision_default_workspace_for_user` slug collision**
- **Found during:** Task 2 verification (`mix demo.reset`)
- **Issue:** First-org provision tried to insert `slug: acme` while manifest org already existed.
- **Fix:** Always `ensure_membership!` + `ensure_agent!` on pre-upserted manifest organizations.
- **Files modified:** `demo/seed/personas.ex`
- **Verification:** `mix demo.reset` exits 0
- **Commit hash:** `fb87560`

**2. [Rule 3 - Naming] `audit_transactions.inserted_at` in delete tx lookup**
- **Found during:** Task 3 verification
- **Issue:** Schema has no `inserted_at` on audit_transactions.
- **Fix:** Order by `occurred_at` instead.
- **Commit hash:** `b3a2d9d`

**3. [Rule 1 - Bug] Temporal `Repo.query!` return shape**
- **Found during:** Task 5 verification
- **Issue:** Pattern-matched `{:ok, _}` but `query!` returns `%Postgrex.Result{}`.
- **Fix:** Call `Repo.query!/2` without tuple match; UUID-encode ids with `Ecto.UUID.dump!/1`.
- **Commit hash:** `cb5c420`

**4. [Rule 3 - Test] demo_reset_test expected zero orgs post-reset**
- **Found during:** plan verification (`mix test demo_reset_test.exs`)
- **Issue:** Reset now truncates then seeds manifest orgs.
- **Fix:** Assert `acme`, `globex`, `offboarded-co` exist; fixture org absent.
- **Commit hash:** `f1bc720`

**Total deviations:** 4 auto-fixed (3 bugs, 1 test). **Impact:** Low — behavior matches D-107-04 and reset+seed contract.

## Issues Encountered

None blocking.

## User Setup Required

None.

## Next Phase Readiness

- Ready for **107-04** (org Y retention purge tail, evidence rows, contract tests).
- **SEED-01/02/03/05** satisfied on disk; formal contract test module still in Plan 04.
- Phase 108 can reference hero tickets, actors, and `demo_last_tuesday` filters from seeded data.

## Self-Check: PASSED

- `cd examples/threadline_phoenix && mix demo.seed 2>&1 | grep -q complete` — PASS
- `mix demo.reset` — PASS (`demo.seed complete`)
- `mix test test/threadline_phoenix/demo_reset_test.exs` — 3 tests, 0 failures
- `mix test test/threadline_phoenix/help_desk_audit_test.exs` — 2 tests, 0 failures
- `mix test test/threadline_phoenix/demo_manifest_test.exs` — 5 tests, 0 failures
- Acme ticket count after reset: 50
- Ticket #4521 `status == closed` after seed
- Hero close `occurred_at` equals `Manifest.last_tuesday()` (second precision)
- Oldest audit row 13 days before `demo_epoch`
- No files under `lib/threadline/` modified in 107-03 commits

---
*Phase: 107-realistic-seed-data-demo-mix-tasks*
*Completed: 2026-05-27*
