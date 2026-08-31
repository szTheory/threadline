---
phase: 198-green-bringup
plan: 23
subsystem: testing
tags: [elixir, ecto, retention, demo-seed, ci, example-app]

# Dependency graph
requires: []
provides:
  - "Two-run failure inventory + cause attribution for mix verify.example's 9-failure baseline"
  - "Root-cause fix for RetentionTail.run/1's unscoped Retention.purge/1 (7 of 9 failures)"
  - "Reusable six-step fix protocol + forbidden-remedy list for plans 198-24..28"
affects: [198-24, 198-25, 198-26, 198-27, 198-28, 198-29]

# Actuals (#2632)
actuals:
  tokens: 62000
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two-run inventory before any fix (non-determinism made explicit, never averaged away)"
    - "Shared-cause grouping — one root cause credited once, not once per symptom"
    - "Library's own documented :cutoff override seam used instead of new library surface"

key-files:
  created:
    - .planning/audits/198-round4-demo-seed.md
  modified:
    - examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex
    - .planning/phases/198-green-bringup/deferred-items.md

key-decisions:
  - "RetentionTail.run/1's Retention.purge(repo: Repo) call gets an explicit epoch-anchored :cutoff (epoch - 60 days) rather than relying on the library's real-wall-clock default, since Threadline.Retention.purge/1 has no per-org scoping by design."
  - "No test assertion was changed — all three SEED-03 manifest heroes tests and SEED-03 leaving agent window's test were already correct; the seed content was wrong, not the assertions."
  - "The fix landed in retention_tail.ex, which was not in the plan's pre-declared files_modified list but was authorized by the plan's own action text (\"the demo-seed module(s) named by the diagnosis\") — logged as a Rule 1 deviation."

patterns-established:
  - "Pattern: two-run failure inventory with explicit union/intersection before any fix, so non-determinism is never silently averaged away."
  - "Pattern: group failures by shared root cause before fixing — one seed fix can resolve N symptom-level test failures."

requirements-completed: []  # GREEN-04 remains Pending per D-01 — this plan produces a readiness signal only, not a verdict; plan 198-29's measured CI run is authoritative.

coverage:
  - id: D1
    description: "Two-run failure inventory for mix verify.example with per-failure module/describe/test/line/class/verbatim-message, union=9, intersection=8, non-determinism marked explicitly"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#two-run-failure-inventory (mix verify.example, run 1 and run 2 captured verbatim)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Cause attribution: 7 of 9 union failures share one root cause (RetentionTail.run/1's unscoped Retention.purge/1); 2 undiagnosed, out of scope"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#cause-attribution + #root-cause-confirmation (manual mix run reproduction against real DB state)"
        status: pass
    human_judgment: false
  - id: D3
    description: "SEED-03 manifest heroes and SEED-03 leaving agent window clusters fixed at cause, with red-then-green teeth proof, no test assertion changed"
    verification:
      - kind: integration
        ref: "examples/threadline_phoenix/test/threadline_phoenix/demo_contract_test.exs (13 tests, 0 failures, two consecutive runs)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Measured mix verify.example failure count strictly lower after the fix (9 -> 1, both after-runs consistent) with a reusable fix protocol on disk for plans 198-24..28"
    verification:
      - kind: other
        ref: ".planning/audits/198-round4-demo-seed.md#measured-after-count + #fix-protocol-for-the-remaining-clusters"
        status: pass
    human_judgment: false
  - id: D5
    description: "GREEN-04 not marked Complete — only a measured CI run (plan 198-29, D-01) is admissible evidence; this plan is a local readiness signal only"
    verification:
      - kind: integration
        ref: "test/threadline/ci_attestation_contract_test.exs + .planning/audits/ci-attestation-33344382035.json"
        status: pass
    human_judgment: false
    rationale: "Per D-01, no local evidence can satisfy this — it requires a human/orchestrator decision to defer to plan 198-29's CI run, which this SUMMARY explicitly does not attempt to substitute for. Discharged by measured CI run 33344382035 per D-01: GREEN-04 is Complete on that run's own job conclusion, not on local evidence."
# Metrics
duration: 45min
completed: 2026-08-28
status: complete
---

# Phase 198 Plan 23: Gap-closure round-4 tracer — demo-seed retention purge cutoff fix Summary

**Diagnosed and fixed a global-age retention purge that was silently deleting hero demo data across every organization instead of just the intended offboarded-co org, dropping `mix verify.example`'s measured failure count from 9 to 1.**

## Performance

- **Duration:** 45 min
- **Started:** 2026-08-28 (see commit timestamps)
- **Completed:** 2026-08-28
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments

- Measured a real, two-run failure inventory for `mix verify.example` (union 9, intersection 8, one non-deterministic timeout test marked explicitly rather than averaged away) — written to `.planning/audits/198-round4-demo-seed.md` before any code was touched.
- Diagnosed the root cause via manual `mix run` reproduction against the real test database: `ThreadlinePhoenix.Demo.Seed.RetentionTail.run/1` called `Threadline.Retention.purge/1` with no `:cutoff` override, so the library's global-age default (real wall-clock `DateTime.utc_now()` minus `keep_days: 30`, with **no per-organization scoping** — confirmed by reading `lib/threadline/retention.ex`'s `WHERE` clauses) deleted every organization's epoch-anchored demo fiction as collateral damage, not just `offboarded-co`'s intended `-90 day` backdate, because real time has now drifted more than 30 days past the frozen demo epoch (2026-05-27).
- Fixed the `SEED-03 manifest heroes` and `SEED-03 leaving agent window` describe blocks at their cause — one function changed (`retention_tail.ex`, passing an explicit epoch-anchored `:cutoff` via the library's own documented "stricter than policy" override seam) — with a captured red-then-green teeth proof (13 tests, 0 failures, two consecutive runs). No test assertion was changed.
- Re-measured `mix verify.example` from the repository root twice after the fix: **9 → 1** failures (both after-runs consistent, `undefined_table` occurrences confirmed `0` in every captured run). The one remaining failure (`admin export status shows seeded job states`) is confirmed unrelated (a `Governance.ExportJob` expiry-label bug, not touched by `Retention.purge/1`) and logged in `deferred-items.md` for a successor round.
- Wrote a reusable six-step fix protocol plus a verbatim forbidden-remedies list to `.planning/audits/198-round4-demo-seed.md` for plans 198-24 through 198-28 to follow as `read_first`.

## Task Commits

1. **Task 1: Measure the real failure inventory over two independent runs, before changing anything** - `0c4e5b44` (docs)
2. **Task 2: Fix the SEED-03 manifest-heroes cluster at its cause, with a red-then-green teeth proof** - `9eab0ce3` (fix)
3. **Task 3: Re-measure the lane, record the drop, and write the fix protocol the expansion plans follow** - `38afb58c` (docs)

## Files Created/Modified

- `.planning/audits/198-round4-demo-seed.md` - two-run failure inventory, cause attribution table, root-cause confirmation transcript, red-then-green teeth proof, measured before/after counts, and the reusable fix protocol
- `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex` - added an epoch-anchored `:cutoff` override to the `Retention.purge/1` call so the global-age purge no longer collaterally deletes other orgs' hero data
- `.planning/phases/198-green-bringup/deferred-items.md` - new dated entry recording the fix and the one remaining, out-of-scope, undiagnosed failure

## Decisions Made

- Used the library's own documented `:cutoff` override (a "stricter than policy" seam `Threadline.Retention.purge/1` already exposes) rather than modifying the library itself — the library's global-age, no-org-scoping design is correct for a real product; the demo seed was misusing it.
- Did not touch `demo_contract_test.exs`, `seed.ex`, `seed/anchors.ex`, `seed/personas.ex`, `seed/support.ex`, or `manifest.ex` — none of those files were the cause; changing any of them would have been either a no-op or, worse, papering over a real seed-content bug with an assertion change.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fix landed in `retention_tail.ex`, not in the plan's pre-declared `files_modified` list**
- **Found during:** Task 2 (root-cause diagnosis)
- **Issue:** The plan's frontmatter `files_modified` and Task 2's `<files>` tag listed `seed.ex`, `seed/anchors.ex`, `seed/personas.ex`, `seed/support.ex`, and `manifest.ex` as the candidate seed-module files, but the actual root cause — an unscoped `Threadline.Retention.purge/1` call — lives in `seed/retention_tail.ex`, which was not on that list.
- **Fix:** Edited `retention_tail.ex` instead, per the plan's own action text authorizing "the demo-seed module(s) named by the diagnosis" (not a fixed enumeration). No other undeclared files were touched.
- **Files modified:** `examples/threadline_phoenix/lib/threadline_phoenix/demo/seed/retention_tail.ex`
- **Verification:** `mix test test/threadline_phoenix/demo_contract_test.exs` — 13 tests, 0 failures, two consecutive runs; `mix verify.example` — 9 → 1 failures.
- **Committed in:** `9eab0ce3`

---

**Total deviations:** 1 auto-fixed (1 Rule 1 — bug fix location correction, authorized by the plan's own text).
**Impact on plan:** No scope creep — the plan explicitly anticipated "the demo-seed module(s) named by the diagnosis" might not match the pre-declared list; the fix stayed within the example app's demo-seed layer and did not touch the library, the test file, `ci.yml`, or `mix.exs`.

## Issues Encountered

None beyond the diagnosis itself (documented above as the plan's core deliverable, not an issue).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `mix verify.example`'s measured failure count dropped from 9 to 1 (union baseline), with the remaining failure named, diagnosed-as-unrelated, and logged for a successor round.
- Plans 198-24 through 198-28 can read `.planning/audits/198-round4-demo-seed.md`'s "Fix protocol for the remaining clusters" section as their own `read_first` and follow the same six-step loop.
- GREEN-04 remains **Pending** — this plan is a local readiness signal only, per D-01; the verdict belongs exclusively to plan 198-29's measured CI run.
- No blocker for the rest of gap-closure round 4.

---
*Phase: 198-green-bringup*
*Completed: 2026-08-28*
