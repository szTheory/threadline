---
phase: 107-realistic-seed-data-demo-mix-tasks
plan: 04
subsystem: demo-ops
tags: [elixir, phoenix, demo-seed, retention, evidence, contract-tests]

requires:
  - phase: 107-realistic-seed-data-demo-mix-tasks
    plan: 03
    provides: mix demo.seed pipeline, hero incidents, temporal backfill
provides:
  - Org Y retention tail with evidence plane snapshots
  - demo_contract_test.exs for SEED-02..05
  - README demo walkthrough section and doc contract
affects:
  - 108 WALKTHROUGH.md scripting against DEMO-MANIFEST and evidence run id
  - Operator WALK-04 org Y purge proof path

tech-stack:
  added: []
  patterns:
    - "RetentionTail: backdate org Y audit → put_env enable retention → purge → evidence"
    - "demo_contract_test uses unboxed_run + semantic fingerprint idempotency"

key-files:
  created:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
    - examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs
    - examples/threadline_phoenix/priv/repo/migrations/20260527172547_threadline_governance_schema.exs
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/manifest.ex
    - examples/threadline_phoenix/config/dev.exs
    - examples/threadline_phoenix/config/test.exs
    - examples/threadline_phoenix/README.md
    - test/threadline/readme_doc_contract_test.exs
    - examples/threadline_phoenix/test/support/fixtures/auth_fixtures.ex

key-decisions:
  - "Retention :enabled stays false in dev.exs; RetentionTail enables via put_env before purge to avoid Pruner starting before Repo"
  - "Governance migration added to example app for retention_runs and evidence_records tables"
  - "user_fixture returns existing confirmed user when demo seed already registered the email"

patterns-established:
  - "Pattern: Evidence retention_run subject_ref includes run_id, org_slug, and organization_id (full ref for list_subject_ref_history)"

requirements-completed: [SEED-02, SEED-03, SEED-04, SEED-05]

duration: 35min
completed: 2026-05-27
---

# Phase 107 Plan 04: Retention Tail + Contract Tests Summary

**Org Y offboard purge is seeded with evidence snapshots; `demo_contract_test.exs` and the example README lock SEED-02..05 for Phase 108.**

## Performance

- **Duration:** 35 min
- **Started:** 2026-05-27T17:25:00Z
- **Completed:** 2026-05-27T18:00:00Z
- **Tasks:** 3
- **Files modified:** 11

## Accomplishments

- `Demo.Seed.RetentionTail` backdates offboarded-co audit rows, runs `Threadline.Retention.purge/1`, records retention_run/policy/trigger_coverage evidence, and asserts org Y audit footprint is empty.
- `demo_contract_test.exs` proves heroes #4521/#4518, redaction, delete attribution, double-reset idempotency fingerprint, and retention evidence.
- Example README documents `mix demo.seed` / `mix demo.reset` with DEMO-MANIFEST and DEMO_USERS links; root doc contract test enforces literals.

## Task Commits

Each task was committed atomically:

1. **Task 1: Org Y retention tail + evidence** - `eab3514` (feat)
2. **Task 2: demo_contract_test.exs** - `62bd7d7` (test)
3. **Task 3: README + doc contract** - `d864e82` (docs)

## Files Created/Modified

- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` - Step 6 purge + evidence
- `examples/threadline_phoenix/priv/repo/migrations/20260527172547_threadline_governance_schema.exs` - Governance + evidence tables
- `examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs` - SEED contract tests
- `examples/threadline_phoenix/README.md` - Demo walkthrough data section
- `test/threadline/readme_doc_contract_test.exs` - Asserts demo mix task strings

## Decisions Made

- Did not set `retention: enabled: true` in `dev.exs` permanently — background Pruner fails if Threadline app starts before `ThreadlinePhoenix.Repo`.
- Used `list_subject_ref_history/3` with full manifest `subject_ref` (plan cited nonexistent `list_runs/1`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Blocker] Missing governance tables in example DB**
- **Found during:** Task 1 verification (`mix demo.reset`)
- **Issue:** `threadline_retention_runs` and `threadline_evidence_records` did not exist after migrate.
- **Fix:** Added `20260527172547_threadline_governance_schema.exs` migration.
- **Files modified:** `priv/repo/migrations/20260527172547_threadline_governance_schema.exs`
- **Commit hash:** `eab3514`

**2. [Rule 1 - Blocker] Retention enabled in dev.exs breaks `mix run` / app.start**
- **Found during:** Task 1 verification
- **Issue:** `Threadline.Retention.Pruner` starts before Repo when `:enabled` is true in config.
- **Fix:** Keep `enabled: false` in `dev.exs`; `RetentionTail` uses `Application.put_env` before purge only.
- **Commit hash:** `eab3514`

**3. [Rule 3 - Test] Full suite failed after demo_manifest_test cleared password env**
- **Found during:** Task 2 full `mix test`
- **Issue:** `demo_manifest_test` on_exit restored nil `demo_seed_password`.
- **Fix:** Set `demo_epoch` / `demo_seed_password` in `config/test.exs`; make `user_fixture` reuse seeded admin.
- **Commit hash:** `d864e82`

**Total deviations:** 3 auto-fixed (3 blockers). **Impact:** Low — behavior matches D-107-06 and SEED requirements.

## Issues Encountered

None blocking after deviations.

## User Setup Required

Run `mix ecto.migrate` in `examples/threadline_phoenix/` once to apply governance schema (included in normal setup).

## Next Phase Readiness

- **Phase 107 complete** — all four plans shipped; SEED-01..05 satisfied.
- Phase 108 can script WALK-04 org Y evidence using `walk-retention-offboarded-co` and empty org Y timeline.
- Phase 108 should add fourth operator incident for #4518 delete attribution (per 107-CONTEXT D-107-05c).

## Self-Check: PASSED

- `cd examples/threadline_phoenix && mix test test/threadline_phoenix/demo_contract_test.exs` — 6 tests, 0 failures
- `cd examples/threadline_phoenix && mix test` — 48 tests, 0 failures
- `grep -q "mix demo.seed" examples/threadline_phoenix/README.md` — PASS
- `grep -q "mix demo.reset" examples/threadline_phoenix/README.md` — PASS
- `grep -q "DEMO-MANIFEST" examples/threadline_phoenix/README.md` — PASS
- `mix test test/threadline/readme_doc_contract_test.exs` — includes demo task test — PASS
- `mix demo.reset` — exits 0, `demo.seed complete`
- No files under `lib/threadline/` modified in 107-04 commits

---
*Phase: 107-realistic-seed-data-demo-mix-tasks*
*Completed: 2026-05-27*
