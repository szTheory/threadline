---
phase: 198-green-bringup
plan: 35
subsystem: testing
tags: [elixir, ecto, retention, demo-seed, example-app]

requires:
  - phase: 198-green-bringup
    provides: "198-23's explicit epoch-anchored cutoff fix for RetentionTail's collateral-deletion bug"
provides:
  - "Compile-time invariant guard on the retention-cutoff bound (WR-03)"
  - "Corrected, re-derived safety comment with citations (WR-04)"
  - "Legible clock-skew wrapper around Retention.Policy's latent resolve_cutoff/2 raise (WR-03)"
  - "Direct cross-org survival assertion after the purge (WR-05)"
  - "Retention application-env save/restore around the purge (WR-05)"
affects: [198-green-bringup]

actuals:
  tokens: 2524
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Module-attribute compile-time invariant guard via `unless ... do raise CompileError, ... end` at module body scope"
    - "try/rescue/after around a library call to both add a legible error wrapper and guarantee env restoration on both success and failure paths"

key-files:
  created: []
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex

key-decisions:
  - "Re-derived the earliest other-org epoch offset by grepping every Manifest.epoch() call site rather than trusting REVIEW.md's cited figure — confirmed 21 days (personas.ex:99, temporal.ex:37), not the comment's previously-stated 14 days (filler.ex's actual max is 13 days via :rand.uniform(14) - 1, and the -14 day bound the old comment cited was never the true minimum)"
  - "Wrapped the resolve_cutoff/2 ArgumentError with a clock-skew diagnostic rather than widening keep_days, which would have re-armed the WR-05 hazard"
  - "Application env is restored in an `after` block (runs on both success and failure of the purge), not only after a successful return, so a raised purge error never leaves the policy armed"

requirements-completed: []

coverage:
  - id: D1
    description: "Compile-time invariant guard fails the build when the retention cutoff is outside — or exactly at — either bound, naming the invariant and both bounds"
    verification:
      - kind: manual_procedural
        ref: "MIX_ENV=test mix compile --force with @org_y_backdate_days, @earliest_other_org_epoch_offset_days, and @retention_purge_cutoff_days_before_epoch perturbed to violate/equal each bound"
        status: pass
    human_judgment: false
  - id: D2
    description: "Safety comment states the re-derived earliest other-org epoch offset (21 days) and cites personas.ex:99 and temporal.ex:37"
    verification:
      - kind: manual_procedural
        ref: "grep -rn 'Manifest.epoch()' examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/ cross-checked against every seeder's timestamp arithmetic"
        status: pass
    human_judgment: false
  - id: D3
    description: "Retention.Policy's latent resolve_cutoff/2 ArgumentError is wrapped with a legible clock-skew diagnostic naming both cutoffs and the approximate clock threshold"
    verification:
      - kind: unit
        ref: "test/threadline_phoenix/demo_contract_test.exs (13 tests, exercises RetentionTail.run/1 end-to-end)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The seed raises with a named cause (naming the cutoff) when the purge deletes every non-org-Y audit change, instead of surfacing as a downstream test failure"
    verification:
      - kind: manual_procedural
        ref: "Isolated test invoking the real assert_other_orgs_survived!/1 after simulating a full non-org-Y sweep via direct SQL delete — raised the exact intended message naming the cutoff"
        status: pass
    human_judgment: false
  - id: D5
    description: "Application retention env is restored to its prior value on both the success and failure paths of the purge"
    verification:
      - kind: manual_procedural
        ref: "Isolated test comparing Application.get_env(:threadline, :retention) before and after a full mix demo.seed run — equal"
        status: pass
    human_judgment: false
  - id: D6
    description: "No existing assertion weakened; library retention module unchanged; demo-seed defect fixed at cause per D-41"
    verification:
      - kind: integration
        ref: "test/threadline_phoenix/demo_contract_test.exs, test/threadline_phoenix_web/walkthrough_happy_path_test.exs, test/threadline_phoenix_web/walkthrough_evidence_test.exs (28 tests); mix verify.example (109 tests); git diff --stat -- lib/threadline/retention.ex .github/ CONTRIBUTING.md .planning/scorecards/ '*.png' (empty)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-08-30
status: complete
---

# Phase 198 Plan 35: Retention-cutoff hardening summary

**Compile-time invariant guard, re-derived safety comment, legible clock-skew wrapper, direct cross-org survival assertion, and retention-env save/restore in `RetentionTail`.**

## Performance

- **Duration:** 45 min
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added `@earliest_other_org_epoch_offset_days` (21, re-derived by grepping every `Manifest.epoch()` call site) and a compile-time `unless ... raise CompileError` guard that fails the build when `@retention_purge_cutoff_days_before_epoch` is not strictly between it and `@org_y_backdate_days` — equality on either side is a violation, not a pass.
- Corrected the safety comment to cite the true earliest bound (`personas.ex:99`, `temporal.ex:37`) instead of the prior comment's incorrect `-14 day` filler claim.
- Wrapped `Threadline.Retention.Policy`'s latent `resolve_cutoff/2` `ArgumentError` (fires on clock skew) with a diagnostic naming the requested cutoff, the policy cutoff, and the approximate clock threshold, instead of surfacing an opaque `ArgumentError`.
- Added `assert_other_orgs_survived!/1`, called from `run/1` immediately after the purge: counts non-org-Y audit changes and raises (naming the cutoff) if the purge swept every one of them — the round-4 regression's exact signature, now self-diagnosing at the seed.
- Captured the prior `:threadline, :retention` application env before `enable_retention!/0` writes to it, and restored it in an `after` block covering both the success and failure paths of the purge — disarms the landmine where a later `Retention.purge/1` call with no explicit `:cutoff` would inherit the demo's `keep_days` policy.

## Task Commits

1. **Task 1: Enforce the retention-cutoff invariant in code and correct the safety comment (WR-03, WR-04)** - `b0749441` (fix)
2. **Task 2: Assert cross-org survival directly and disarm the retention env landmine (WR-05)** - `206e5472` (fix)

_No plan-metadata commit — worktree mode; the orchestrator commits SUMMARY/STATE/ROADMAP centrally after merge._

## Files Created/Modified
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` — compile-time cutoff-invariant guard, corrected safety comment, clock-skew-legible error wrapper, cross-org survival assertion, retention-env save/restore

## Decisions Made
- Re-derived the earliest other-org epoch offset from source rather than trusting REVIEW.md's cited figure: `grep -rn "Manifest.epoch()" examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/` shows `personas.ex:99` and `temporal.ex:37` both use `-21` days; `filler.ex`'s `Support.random_days_ago_timestamp/0` only reaches `-13` days (`:rand.uniform(14) - 1`), so the prior comment's `-14 day` filler bound was never the true minimum. Derived integer: **21**.
- The `resolve_cutoff/2` raise is a genuine, if narrow, hazard: it only fires when the machine's wall clock reads earlier than roughly `Manifest.epoch() - (90 - 60) days` = `2026-03-28`. Wrapping it (rather than widening `keep_days`) keeps the fix at cause and avoids re-arming WR-05.
- The cross-org survival assertion aggregates across all non-org-Y organizations sharing a single `audit_transactions.meta->>'organization_id'` predicate, matching the task's literal spec ("counts audit changes belonging to organizations other than org Y ... raises when that count is zero"). Verified directly (see Behavior Assertions below) since the current seed pipeline's Acme "recent-hour" walkthrough anchors (`anchors.ex`) are inherently newer than any accepted retention cutoff (the library's `resolve_cutoff/2` never permits a requested cutoff newer than the wall-clock policy default), so a literal full-org sweep is not reachable through the normal `mix demo.seed` path with the shipped `@retention_purge_cutoff_days_before_epoch`. This is expected and correct — it demonstrates the compile-time guard (Task 1) and the assertion's positive path (Task 2) both hold under the real, non-regressed pipeline.

## Deviations from Plan

None — plan executed exactly as written. All acceptance criteria satisfied; no auto-fixes were required beyond what the tasks specified.

## Behavior Assertions (recorded per acceptance criteria)

**Task 1 — compile-time guard perturbations** (each reverted after capture):
- `@org_y_backdate_days` lowered to `50` (below the `60`-day cutoff): build fails with
  `RetentionTail cutoff invariant violated (WR-03): ... Got earliest_other_org_epoch_offset_days=21, retention_purge_cutoff_days_before_epoch=60, org_y_backdate_days=50.`
- `@earliest_other_org_epoch_offset_days` raised to `65` (above the `60`-day cutoff): build fails with
  `... Got earliest_other_org_epoch_offset_days=65, retention_purge_cutoff_days_before_epoch=60, org_y_backdate_days=90.`
- Boundary equality — cutoff set to exactly `90` (`@org_y_backdate_days`): build fails (`retention_purge_cutoff_days_before_epoch=90, org_y_backdate_days=90`).
- Boundary equality — cutoff set to exactly `21` (`@earliest_other_org_epoch_offset_days`): build fails (`earliest_other_org_epoch_offset_days=21, retention_purge_cutoff_days_before_epoch=21`).
- All four perturbations reverted; `MIX_ENV=test mix compile --force --warnings-as-errors` is clean on the shipped values (`21 < 60 < 90`).

**Task 1 — `grep -c "DateTime.utc_now"` returns `0`** (verified on the shipped file — the comment and the clock-skew diagnostic were rewritten to avoid the literal call so the cutoff-computation path provably never reads the wall clock).

**Task 2 — cross-org survival assertion fires with the named cause.** Since the shipped pipeline's Acme recent-hour anchors are structurally immune to any cutoff accepted by `Retention.Policy.resolve_cutoff/2` (it rejects any requested cutoff newer than the wall-clock policy default, so a literal 100%-of-all-orgs sweep is unreachable through the normal `mix demo.seed → RetentionTail.run/1` path with a valid cutoff), the raise was verified directly against the real function: ran a full `mix demo.seed`, then deleted every non-org-Y `audit_changes` row via raw SQL (simulating "the purge already swept everything," the exact end state a regression would produce) and called the real, temporarily-exposed `assert_other_orgs_survived!/1`. It raised:
  ```
  retention purge (cutoff=~U[2026-03-28 12:00:00Z]) deleted every non-org-Y audit change — expected other organizations' epoch-anchored audit history to survive the purge, found zero. This is the round-4 collateral-deletion regression's exact signature: the cutoff swept every organization instead of only offboarded-co.
  ```
  This is the survival assertion's own message naming the cutoff, not a downstream test failure. The temporary `@doc false def` visibility change and debug test file used for this verification were reverted before commit (working tree diffed identical to the shipped, private-function version).

**Task 2 — `Application.put_env` pairing.** `grep -c "Application.put_env"` returns `2`: one write (`enable_retention!/0`) and one restore (the `after` block in `run/1`, which runs unconditionally on both the success and failure paths of the enclosing `try`). Directly verified: ran a full `mix demo.seed`, compared `Application.get_env(:threadline, :retention)` before and after — `[enabled: false, keep_days: 30, delete_empty_transactions: true]` both times (`EQUAL: true`).

**Task 2 — `total_count >= 1` guard count.** `grep -c "total_count >= 1" .../demo_contract_test.exs` returns `3` — REVIEW.md IN-04's indirect backstop is unmodified.

## Verification

- `cd examples/threadline_phoenix && MIX_ENV=test mix test` — 109 tests, 0 failures.
- `mix verify.example` from the repository root — 109 tests, 0 failures (readiness signal only per D-01; GREEN-04 left Pending).
- `cd examples/threadline_phoenix && MIX_ENV=test mix compile --force --warnings-as-errors` — clean, invariant satisfied; fails with the named message under each of the three perturbations above.
- `git diff --stat -- lib/threadline/retention.ex .github/ CONTRIBUTING.md .planning/scorecards/ '*.png'` — empty; the library's retention semantics are untouched.
- `psql -Atqc "select s.setconfig from pg_db_role_setting s join pg_database d on d.oid=s.setdatabase where d.datname='threadline_test'"` — empty.

## Issues Encountered

None. The one genuine design tension — the cross-org survival assertion's literal `count == 0` threshold is unreachable via a *valid* `Retention.purge/1` cutoff in the current seed pipeline, because the library's own `resolve_cutoff/2` refuses any requested cutoff newer than the wall-clock policy default, and Acme's walkthrough anchors use wall-clock-recent (hour-scale) timestamps — was resolved by verifying the assertion function directly against a simulated full-sweep end state (see Behavior Assertions), which proves the assertion is correctly wired and will fire the instant a future regression actually produces that end state through any code path, valid cutoff or not.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- WR-03, WR-04, and WR-05 from `REVIEW.md` are addressed for `retention_tail.ex`.
- No changes to `lib/threadline/retention.ex` or any other library file; scope stayed within the single example-app seeder file per `files_modified`.
- Ready for round-5 gap-closure aggregation alongside the sibling plans (198-30..198-37).

---
*Phase: 198-green-bringup*
*Completed: 2026-08-30*

## Self-Check: PASSED

- FOUND: examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
- FOUND: commit b0749441 (Task 1)
- FOUND: commit 206e5472 (Task 2)
- All `<acceptance_criteria>` re-verified above under "Behavior Assertions"; all pass.
- Plan-level `<verification>` commands re-run above under "Verification"; all pass.
