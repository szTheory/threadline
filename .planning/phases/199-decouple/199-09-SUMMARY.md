---
phase: 199-decouple
plan: "09"
subsystem: testing
tags: [repository-hygiene, exunit, tdd, git-history, documentation-contracts]

requires:
  - phase: 198-green-bringup
    provides: "durable Plan 198-41 summary/ratification evidence and the historical HANDOFF citation"
  - phase: 199-decouple
    provides: "D-13 through D-16 and D-21 deletion, provenance, and documentation-truth constraints"
provides:
  - "synthetic-first and live scanners for tracked removal targets, root one-off executables, and active stale-path citations"
  - "restored README canonical-wording assertion with a deliberate mutation control"
  - "surgical removal of four dead tracked artifacts with full recovery commits"
  - "historically truthful HANDOFF citation addendum and a durable removal inventory"
affects: [DECOUPLE-03, DECOUPLE-04, phase-199-verification, repository-hygiene]

actuals:
  tokens: 6633
  tasks: 2
  commits: 3
plan_head_before: c640cf37162244bc85aad9641fdf17a6f3d4916e

tech-stack:
  added: []
  patterns:
    - "Synthetic-first repository contract followed by an activated git ls-files live invariant"
    - "Historical input citations remain valid only with an exact supersession marker and durable current evidence"
    - "Deleted artifacts are recovered by full commit SHA, never by retaining tombstones in active HEAD"

key-files:
  created:
    - .planning/phases/199-decouple/199-REMOVAL-INVENTORY.md
    - test/threadline/removed_artifact_contract_test.exs
  modified:
    - test/threadline/readme_doc_contract_test.exs
    - .planning/phases/198-green-bringup/198-41-PLAN.md
    - .planning/HANDOFF.json
    - .planning/ROADMAP.md.bak
    - update_roadmap.rb
    - fix_tests.exs

key-decisions:
  - "Active citation detection is derived from executable/current-document classes; a historical live-input citation is allowed only when the same artifact has an exact Phase 199 supersession marker."
  - "Git history plus full recovery commits replaces archive copies or tombstones for all four removed artifacts."

patterns-established:
  - "Removal contract: derive the tracked set from git ls-files, report violations as file/line/target, and prove a bad synthetic tree before scanning the live repository."

requirements-completed: [DECOUPLE-03, DECOUPLE-04]

coverage:
  - id: D1
    description: "The scanner rejects stale citations and tracked/root one-off artifacts synthetically, then passes against the live tracked repository."
    requirement: DECOUPLE-03
    verification:
      - kind: integration
        ref: "test/threadline/removed_artifact_contract_test.exs#scanner reports a removed-path citation with file and line and accepts a clean tree"
        status: pass
      - kind: integration
        ref: "test/threadline/removed_artifact_contract_test.exs#live repository has no removed targets, root one-offs, or active citations"
        status: pass
    human_judgment: false
  - id: D2
    description: "README operator-support wording is asserted against current canonical copy and a temporary mutation proves the contract fails closed."
    requirement: DECOUPLE-04
    verification:
      - kind: unit
        ref: "test/threadline/readme_doc_contract_test.exs#README operator support wording contract rejects a temporary mutation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exactly four named artifacts are absent from the filesystem and Git index, inventoried with full recovery SHAs, and repeated live scans are byte-idempotent."
    requirement: DECOUPLE-03
    verification:
      - kind: other
        ref: "git ls-files/absence checks plus repeated live scan; status SHA-256 840265939457892f1708ebd14fb26e33ac7e645143d9878a765a2260312aba97"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 09: Dead Artifact Removal and Documentation Truth Summary

**Four preflighted dead artifacts were removed with full recovery identities while synthetic and live contracts now block stale citations, root one-offs, and README wording regressions.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-11T04:46:20Z
- **Completed:** 2026-09-11T04:53:08Z
- **Tasks:** 2
- **Files modified:** 8 production/planning files

## Accomplishments

- Built a scanner that derives tracked, executable, and current-document classes, reports stale dependencies as file/line/target violations, and is proven first against bad and clean synthetic trees.
- Restored the README contract to its current optional-in-tree/support-guarantee wording and proved its sensitivity with a temporary in-memory mutation.
- Removed exactly `.planning/ROADMAP.md.bak`, `.planning/HANDOFF.json`, `update_roadmap.rb`, and `fix_tests.exs`; recorded purpose, last use, supersession, and full recovery commit for each.
- Preserved Plan 198-41's historical truth with an execution-time supersession addendum, then ran the live invariant repeatedly with byte-identical status and diff snapshots.

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: failing scanner and README mutation contracts** — `5a2ffb11` (test)
2. **Task 1 GREEN: synthetic scanner and canonical README wording contract** — `827722a0` (feat)
3. **Task 2: provenance repair, exact removals, and live invariant** — `3253a402` (chore)

**Plan metadata:** committed separately before sequential STATE/ROADMAP synchronization.

## Files Created/Modified

- `test/threadline/removed_artifact_contract_test.exs` — synthetic scanner mechanics, consumer classification, file/line diagnostics, root-one-off rule, and live `git ls-files` invariant.
- `test/threadline/readme_doc_contract_test.exs` — restored current-wording assertion and temporary mutation proof.
- `.planning/phases/199-decouple/199-REMOVAL-INVENTORY.md` — purpose, last meaningful use, superseding evidence, full recovery commits, and recovery procedure.
- `.planning/phases/198-green-bringup/198-41-PLAN.md` — minimal historical addendum for the removed HANDOFF input.
- `.planning/HANDOFF.json`, `.planning/ROADMAP.md.bak`, `update_roadmap.rb`, and `fix_tests.exs` — intentionally deleted after exact preflight.

## Decisions Made

- The scanner treats runtime/executable references as live and limits current-document scanning to public docs, active project authority surfaces, and the one historical plan with a known live-input citation. Diagnostic removal prose is not itself a dependency.
- A historical live-input citation is allowed only when its document carries the exact marker stating that the path existed at execution time and was superseded/removed in Phase 199, with durable evidence named.
- Recovery uses the full commit SHAs recorded in the inventory; no archive junk drawer or retained tombstone was created.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` verification syntax**

- **Found during:** Task 1 RED execution
- **Issue:** The installed Mix task rejects `-x` as an unknown option before ExUnit discovers any tests, so the literal plan command cannot provide valid RED or GREEN evidence.
- **Fix:** Ran the same two focused test files without `-x`; the RED run executed 24 tests with the named assertions failing, and the final GREEN run executed 25 tests with zero failures.
- **Files modified:** None beyond the planned test files.
- **Verification:** `gsd-tools check tdd-red-evidence` returned `RED_EVIDENCE_OK`; the final focused run passed 25/25.
- **Committed in:** `5a2ffb11`, `827722a0`, and `3253a402` as the task work guarded by those runs.

**2. [Rule 3 - Blocking] Reconciled Phase 199 roadmap progress after the canonical handler declined the legacy layout**

- **Found during:** Sequential state synchronization after the SUMMARY commit.
- **Issue:** `roadmap.update-plan-progress 199` found the 14 plans and five summaries but returned `missing_phase_details`, leaving the visible Plan 09 checklist and `4/14` progress row stale.
- **Fix:** Marked only `199-09-PLAN.md` complete and advanced the existing Phase 199 row to `5/14 In Progress`, matching the handler's live counts.
- **Files modified:** `.planning/ROADMAP.md`; the deviation is also registered in `.planning/WINDOWS.md`.
- **Verification:** The Phase 199 checklist has five completed entries, its progress row reads `5/14`, and the remaining nine plans remain unchecked.

---

**Total deviations:** 2 auto-fixed (2 blocking tooling/layout issues).
**Impact on plan:** The supported test command exercises the exact planned files without weakening discovery or assertions; the roadmap reconciliation changes metadata only and matches the live five-summary count.

## TDD Gate Compliance

- **RED:** `5a2ffb11`; the named stale-citation assertion failed because the scanner returned `[]`. The evidence classifier returned `RED_EVIDENCE_OK` with 24 discovered tests and three intentional assertion failures.
- **GREEN:** `827722a0`; the scanner and README predicate implementation passed the focused 24-test suite.
- **REFACTOR:** No separate refactor commit was needed; the GREEN implementation remained small and the final expanded live suite passed 25/25.

## Issues Encountered

- `mix verify.format` remains red on four pre-existing Phase 198 files (`e2e_preflight_contract_test.exs`, `phase198_automation_policy_test.exs`, `phase198_nyquist_contract_test.exs`, and `main_ci_observer_contract_test.exs`). This exact drift was already registered in Phase 199's `deferred-items.md` by Plan 199-01. None was modified here; both plan-owned test files pass direct `mix format --check-formatted`.
- The checkout had no active asdf Elixir/Erlang selection. Verification used the already-installed `Elixir 1.19.5-otp-27` with `Erlang 27.3.4.15` through command-scoped environment variables and did not modify the user's untracked `.tool-versions`.

## User Setup Required

None.

## Next Phase Readiness

- DECOUPLE-03 and DECOUPLE-04 now have executable positive controls and a live tracked-tree invariant.
- Later Phase 199 plans can proceed without the four dead paths; recovery identities remain explicit in `199-REMOVAL-INVENTORY.md`.
- The already-registered Phase 198 formatter drift remains outside this plan's scope.

## Self-Check: PASSED

- `199-REMOVAL-INVENTORY.md`, `removed_artifact_contract_test.exs`, and `readme_doc_contract_test.exs` exist.
- Commits `5a2ffb11`, `827722a0`, and `3253a402` resolve as commit objects.
- All four authorized removal targets are absent from both the filesystem and `git ls-files`; the remaining root tracked `.exs` files are only `.credo.exs`, `.formatter.exs`, and `mix.exs`.
- Focused final verification passes 25 tests with zero failures, and both changed test files are formatter-clean.
- The live scanner ran before and after snapshots with byte-identical status and diff evidence; `git diff --check` passes.
- No stub, skipped test, new network/auth/schema boundary, or untracked scratch deletion was introduced.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
