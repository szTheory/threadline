---
phase: 198-green-bringup
plan: 30
subsystem: testing
tags: [exunit, postgres, advisory-lock, mix-task, ci]

requires:
  - phase: 198-green-bringup
    provides: GREEN-04 CI measurement chain (198-CI-MEASUREMENT.md) identifying the demo_reset_test.exs:56 cold-compile timeout as the sole remaining blocker
provides:
  - Prod-guard test (demo_reset_test.exs:56) restructured so the cold MIX_ENV=prod compile runs once in setup_all, outside the per-test ExUnit timeout budget
  - Measured cold/warm MIX_ENV=prod compile figures and warm guard-only mix demo.reset figure recorded as integers
  - Namespaced, bounded, abnormal-exit-safe advisory lock taken at Demo.Reset.run/1 and Demo.Seed.run/0 (every demo seed/reset entry point), replacing WalkthroughCase's session-scoped unnamespaced lock
affects: [198-31, 198-37, GREEN-04, GREEN-07]

actuals:
  tokens: 46000
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "setup_all for one-time expensive setup outside ExUnit's per-test :timeout budget"
    - "pg_try_advisory_lock/2 bounded retry loop (never blocking pg_advisory_lock) with a named application-level timeout error on exhaustion"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex
    - examples/threadline_phoenix/test/support/walkthrough_case.ex

key-decisions:
  - "No @tag timeout: added to demo_reset_test.exs:56 — the measured warm guard-only mix demo.reset figure (0.748s) sits comfortably inside ExUnit's 60000ms default, and a tag that isn't needed is itself a small mask."
  - "Lock stays session-scoped (via bounded pg_try_advisory_lock retry + explicit unlock in after), not transaction-scoped, because Seed's submodules deliberately open many independent Repo.transaction/1 calls to produce distinct audit transactions for the seeded fiction; one outer transaction would collapse them into a single Postgres transaction."
  - "Retry-exhaustion raises our own named RuntimeError instead of falling back to a blocking pg_advisory_lock/2 bounded by SET lock_timeout, per the plan's acceptance criteria that the unbounded blocking form must be gone from all three files (grep -c 'pg_advisory_lock(' == 0 everywhere)."
  - "Reset.run/1 and Seed.run/0 each independently take the lock (not just Reset delegating to Seed) because mix demo.seed calls Seed.run/0 directly without going through Reset.run/1; Postgres session advisory locks are reentrant, so the nested case (Reset.run/1 calling Demo.Seed.run/0 internally) is safe."

requirements-completed: [GREEN-04]

coverage:
  - id: D1
    description: "Cold MIX_ENV=prod compile moved out of the per-test ExUnit timeout budget in demo_reset_test.exs via setup_all; both original assertions kept verbatim"
    requirement: GREEN-04
    verification:
      - kind: integration
        ref: "cd examples/threadline_phoenix && rm -rf _build/prod && MIX_ENV=test mix test test/threadline_phoenix/demo_reset_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Demo seed/reset advisory lock moved to Reset.run/1 and Seed.run/0 (every entry point), namespaced with a fixed classid, bounded, abnormal-exit-safe; WalkthroughCase's disproven comment corrected"
    requirement: GREEN-04
    verification:
      - kind: integration
        ref: "cd examples/threadline_phoenix && MIX_ENV=test mix test test/threadline_phoenix/demo_reset_test.exs test/threadline_phoenix/demo_contract_test.exs test/threadline_phoenix_web/walkthrough_happy_path_test.exs test/threadline_phoenix_web/walkthrough_evidence_test.exs test/mix/tasks/threadline_evidence_show_example_test.exs"
        status: pass
      - kind: manual_procedural
        ref: "manual psql pg_advisory_lock(84672301,1) hold + demo_reset_test.exs:43 run — failed with named lock-timeout error at 45.7s, not a hang"
        status: pass
    human_judgment: false
  - id: D3
    description: "mix verify.example run twice consecutively from repo root, both 109 tests / 0 failures — readiness signal only, explicitly not GREEN-04 evidence per D-01"
    verification:
      - kind: integration
        ref: "mix verify.example (run 1 and run 2)"
        status: pass
    human_judgment: true
    rationale: "Per D-01 this local figure is a readiness signal only, not admissible GREEN-04 evidence — a measured CI run is required for that, which is out of scope for this plan."

duration: 35min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 30: Cold-compile budget fix + abnormal-exit-safe demo seed/reset lock Summary

**Moved the cold `MIX_ENV=prod` compile out of `demo_reset_test.exs`'s per-test ExUnit budget via `setup_all`, and replaced the unnamespaced session-scoped advisory lock in `WalkthroughCase` with a bounded, namespaced lock taken at every demo seed/reset entry point (`Reset.run/1`, `Seed.run/0`).**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-30T19:35:00Z (approx.)
- **Completed:** 2026-08-30T20:03:09Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments

- `demo_reset_test.exs:56`'s prod-guard test now passes from a genuinely cold `_build/prod`, with the cold `MIX_ENV=prod mix compile` cost paid once in `setup_all` (not subject to ExUnit's per-test timeout) instead of inline inside the timed test body — this is the exact condition (`ExUnit.TimeoutError` at line 69, 60000ms budget) that failed on CI.
- Measured, not guessed: cold `MIX_ENV=prod mix compile` = **30.3s**, warm `MIX_ENV=prod mix compile` = **0.73s**, warm guard-only `MIX_ENV=prod mix demo.reset` (guard check only, `DEMO_ALLOW_RESET` unset) = **0.748s**. The guard-only figure sits comfortably inside ExUnit's 60000ms default, so no `@tag timeout:` was added — recorded explicitly rather than silently omitted.
- Demo seed/reset serialization moved from `WalkthroughCase`'s session-scoped, unnamespaced `pg_advisory_lock(1)` (which only covered `WalkthroughCase`'s own two callers) into `Demo.Reset.run/1` and `Demo.Seed.run/0` themselves, so all five `async: false` seeding test modules **and** the `mix demo.reset` / `mix demo.seed` tasks are covered (WR-02 problem 1).
- The lock is namespaced with a fixed Threadline classid (`84_672_301`) + objid (`1`) instead of an unnamespaced `:erlang.phash2/1` hash (IN-02), exposed via `Reset.advisory_lock_classid/0` / `Reset.advisory_lock_objid/0` so `Seed` references the same canonical value.
- The lock cannot be stranded by an abnormal process exit: `pg_try_advisory_lock/2` is retried in a bounded loop (90 attempts × 500ms = 45s) rather than the blocking, unbounded `pg_advisory_lock/1`; on retry exhaustion the code raises its own named `RuntimeError` ("demo seed lock: timed out after 45000ms...") instead of falling back to any blocking `pg_advisory_lock` call — verified with a real teeth-proof (see below), not just unit tests (WR-01).
- `WalkthroughCase`'s comment no longer claims "two concurrent unboxed seed/reset cycles" can occur intra-run — all five seeding modules are `async: false` and ExUnit never runs two `async: false` modules concurrently, so that mechanism was structurally impossible. The comment now names the surviving mechanism: cross-OS-process contention (a parallel CI lane, a developer running `mix demo.seed`, or a second `mix test` against the same database) (WR-02 problem 2).

## Task Commits

1. **Task 1: Move the cold MIX_ENV=prod compile out of the per-test ExUnit budget in demo_reset_test.exs, measured not guessed** - `1fe99275` (fix)
2. **Task 2: Take the demo seed/reset advisory lock at every entry point, abnormal-exit-safe and namespaced (WR-01, WR-02, IN-02)** - `e06e44b6` (fix)

## Files Created/Modified

- `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` - added `setup_all` running `MIX_ENV=prod mix compile` once, outside the per-test timeout; no `@tag timeout:` needed (measured figure comfortably inside 60000ms default); both original assertions unchanged
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex` - added `@advisory_lock_classid`/`@advisory_lock_objid`, `with_demo_lock/1`, bounded `pg_try_advisory_lock/2` retry loop, `Reset.run/1` now wraps its work in `with_demo_lock/1`
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` - `Seed.run/0` independently takes the same namespaced lock (its own bounded retry loop referencing `Reset`'s classid/objid), since `mix demo.seed` calls it directly without going through `Reset.run/1`
- `examples/threadline_phoenix/test/support/walkthrough_case.ex` - removed `@demo_seed_lock_key` and the `pg_advisory_lock(1)`/`pg_advisory_unlock(1)` wrapper; comment corrected to the surviving cross-OS-process contention mechanism

## Decisions Made

- No `@tag timeout:` added to the prod-guard test — the measured warm guard-only figure (0.748s) is comfortably inside ExUnit's 60000ms default; adding an unneeded tag would itself be a small mask, per the plan's own framing.
- The lock stays session-scoped (bounded retry + explicit `after` unlock) rather than transaction-scoped, because `Seed`'s submodules deliberately open many independent `Repo.transaction/1` calls — each producing its own distinct audit transaction for the seeded fiction. Wrapping the whole pipeline in one outer transaction, as the reviewer's illustrative `pg_advisory_xact_lock` example suggested, would have collapsed those into a single Postgres transaction and silently changed the shape of the seeded audit trail — a real, verified reason (per the task's own instruction to verify before assuming), not a shortcut.
- On retry exhaustion, the code raises its own named `RuntimeError` rather than falling back to a blocking `pg_advisory_lock/2` bounded by `SET lock_timeout`. The plan's acceptance criteria require zero occurrences of the unbounded blocking form (`pg_advisory_lock(`) in all three touched files; `SET lock_timeout = '45s'` is still issued as a real defensive statement (bounds any other blocking wait the connection might incur), but the actual bound on our own retry loop is enforced entirely in Elixir via the bounded `pg_try_advisory_lock/2` loop.
- `Reset.run/1` and `Seed.run/0` each independently acquire the lock rather than only `Reset.run/1` delegating through a single guarded call, because `mix demo.seed` invokes `Seed.run/0` directly without going through `Reset.run/1`. This is safe because PostgreSQL session-scoped advisory locks are reentrant per session/backend connection (the same connection acquiring the same key twice succeeds immediately and must be matched by an equal number of unlocks) — confirmed functionally by the full five-module test suite passing with `Reset.run/1` calling `Demo.Seed.run/0` internally while both hold the lock.

## Deviations from Plan

None - plan executed exactly as written. One clarification worth recording as a course-correction during execution: the plan's `<action>` text for Task 2 suggested "use `pg_try_advisory_lock` in a bounded retry loop... and set `lock_timeout` to `'45s'`" without fully specifying what happens on retry exhaustion. The task's own acceptance criteria (`grep -c 'pg_advisory_lock(' ... returns 0 for every file`) forecloses a blocking `pg_advisory_lock` fallback bounded by `lock_timeout`, so retry exhaustion raises a named `RuntimeError` instead — this is the only way to satisfy both "never leave the wait unbounded" and "zero occurrences of the unbounded blocking form" simultaneously, and it is what the acceptance criteria's own behavior-assertion test (a manual psql lock hold causing a "named lock-timeout error... within the bounded wait, not hang indefinitely") actually verifies. This was resolved by re-reading the acceptance criteria and design intent together rather than treating the illustrative prose as a literal implementation spec; both `<verify>` commands and all acceptance criteria pass as a result. Not tracked as a Rule 1-4 deviation since no plan instruction was contradicted or skipped — the acceptance criteria themselves resolved the ambiguity in the prose.

## Issues Encountered

- First two attempts at the manual "teeth proof" (holding an advisory lock in a background `psql` session, then running the contention test) were invalidated by the background `psql` process dying when its parent Bash tool invocation exited (backgrounded jobs are not guaranteed to survive across separate tool calls in this environment). Fixed by using `nohup psql ... < /dev/null & disown` and a long (300s) `pg_sleep`, then verifying the lock was genuinely held via `pg_locks` immediately before running the test. The final, valid run confirmed the test fails with the named lock-timeout error at ~45.7s (see `coverage` D2 above). Leftover fixture rows from the invalidated attempts (`ephemeral-fixture-org`, stray `threadline_export_jobs` rows) were cleaned up directly via `psql` before the final full-suite and `mix verify.example` runs; all runs after cleanup were green.
- Pre-existing background noise unrelated to this plan: `Threadline.Export.CleanupTask` GenServer occasionally logs a `DBConnection.OwnershipError` (`cannot find ownership process for ...`) during `demo_reset_test.exs` and other unboxed-run tests. This is a supervised background process racing the sandbox's ownership boundary, not caused by this plan's changes (it appeared in test output before Task 1/2 were applied) and does not fail any test. Not modified — out of scope per the deviation-rules scope boundary (pre-existing, unrelated to current task).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GREEN-04's sole remaining blocker (`demo_reset_test.exs:56` cold-compile timeout) is closed locally: cold-from-clean `_build/prod` run passes, and `mix verify.example` reports `109 tests, 0 failures` on two consecutive runs. **This is a readiness signal only per D-01 — GREEN-04 is NOT marked Complete by this plan.** A measured CI run remains the only admissible evidence; that is 198-37's / a later plan's concern, not this one's.
- WR-01 and WR-02 from `REVIEW.md` are both closed with verified, not just asserted, fixes (see coverage D2's manual teeth-proof).
- IN-02 (unnamespaced `phash2` classid) is closed.
- No gate file, ruleset, scorecard, or PNG baseline was touched (`git diff --stat` over the D-39/D-42 interlock paths is empty, confirmed above).
- `threadline_test`'s `search_path` remains unset (confirmed empty via the standing check) — never add one.

## Self-Check: PASSED

- `examples/threadline_phoenix/test/threadline_phoenix/demo_reset_test.exs` — FOUND (modified)
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/reset.ex` — FOUND (modified)
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed.ex` — FOUND (modified)
- `examples/threadline_phoenix/test/support/walkthrough_case.ex` — FOUND (modified)
- Commit `1fe99275` — FOUND in `git log --oneline --all`
- Commit `e06e44b6` — FOUND in `git log --oneline --all`
- All plan-level `<verification>` commands re-run and passed (cold prod-guard test, `mix verify.example` ×2 = 109/0 both runs, D-39/D-42 diff-stat empty, `search_path` empty)
- All task-level `<acceptance_criteria>` re-verified via grep/test commands above; all pass

---

*Phase: 198-green-bringup*
*Completed: 2026-08-30*
