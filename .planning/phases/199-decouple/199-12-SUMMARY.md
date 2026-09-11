---
phase: 199-decouple
plan: "12"
subsystem: testing
tags: [decoupling, exunit, tdd, planning-independence, repository-hygiene]

requires:
  - phase: 198-green-bringup
    provides: "completed Phase-198 audit, ref-disposition, prohibition, Nyquist, and terminal-certification receipts"
  - phase: 199-decouple
    provides: "D-01, D-13, D-16, and D-21 planning-independence and surgical-retirement constraints"
provides:
  - "synthetic-positive-control and live tracked-source scanner for executable planning-history reads"
  - "live-source row focus, dialog accessibility, animation, transition, and reduced-motion contracts without historical receipt dependencies"
  - "exact retirement of eight completed contract tests and two Phase-198 verifier scripts"
  - "ten-row recovery inventory with purpose, last meaningful use, superseding evidence, and full Git SHA"
affects: [DECOUPLE-01, DECOUPLE-03, phase-199-verification, default-test-surface]

actuals:
  tokens: 72516
  tasks: 2
  commits: 3
plan_head_before: 687f7e336f7d6d912ca321d5650b0e1c15943b7e

tech-stack:
  added: []
  patterns:
    - "Synthetic-first source scanner followed by a git ls-files-derived live contract"
    - "Completed planning receipts move out of the executable surface while live source invariants remain"
    - "Every retired executable is recoverable by its exact full commit SHA"

key-files:
  created:
    - test/threadline/planning_dependency_contract_test.exs
    - .planning/phases/199-decouple/199-RETIRED-CONTRACTS.md
  modified:
    - test/threadline/row_history_focus_evidence_contract_test.exs
    - test/threadline/operator_surface/style_contract_test.exs
    - test/threadline/ci_attestation_contract_test.exs
    - test/threadline/phase06_nyquist_ci_contract_test.exs
    - test/threadline/removed_artifact_contract_test.exs
    - .planning/phases/199-decouple/deferred-items.md
  deleted:
    - test/threadline/ia_lock_doc_contract_test.exs
    - test/threadline/phase198_automation_policy_test.exs
    - test/threadline/phase198_decision_attestation_test.exs
    - test/threadline/phase198_nyquist_contract_test.exs
    - test/threadline/phase198_prohibition_resolution_contract_test.exs
    - test/threadline/phase198_ref_disposition_contract_test.exs
    - test/threadline/phase198_terminal_certification_contract_test.exs
    - test/threadline/phase198_zero_human_uat_contract_test.exs
    - bin/verify-phase198-evidence
    - bin/verify-phase198-ref-disposition

key-decisions:
  - "The live scanner derives ExUnit, Mix-task, mix.exs, and workflow inputs from git ls-files, excludes only its own synthetic-control source, and reports violations by file and line."
  - "The scanner owns private planning-history paths; the D-01 operator evidence corpus remains a separately owned fixture migration completed by Plans 199-02 through 199-08."
  - "CI-attestation, Phase-06 CI, and removed-artifact contracts retain their live recorder/workflow/repository assertions while completed planning-prose receipt checks are retired."

patterns-established:
  - "Planning receipt retirement: prove scanner teeth synthetically, preserve current behavior checks, record exact recovery identities, then remove and activate the live scan in one commit."

requirements-completed: [DECOUPLE-01, DECOUPLE-03]

coverage:
  - id: D1
    description: "A synthetic planning-backed File.read! produces an exact file/line violation while diagnostic prose remains accepted."
    requirement: DECOUPLE-01
    verification:
      - kind: unit
        ref: "test/threadline/planning_dependency_contract_test.exs#reports planning-backed file reads with their source location"
        status: pass
      - kind: unit
        ref: "test/threadline/planning_dependency_contract_test.exs#accepts planning paths used only as diagnostic text"
        status: pass
    human_judgment: false
  - id: D2
    description: "Tracked active ExUnit, Mix, and CI sources are derived from Git and contain no executable private planning-history reads."
    requirement: DECOUPLE-01
    verification:
      - kind: integration
        ref: "test/threadline/planning_dependency_contract_test.exs#tracked active ExUnit, Mix, and CI sources do not read planning history"
        status: pass
    human_judgment: false
  - id: D3
    description: "Exactly ten completed executable receipts are absent and each has a complete recovery row with a full SHA."
    requirement: DECOUPLE-03
    verification:
      - kind: other
        ref: "git diff --diff-filter=D plus 199-RETIRED-CONTRACTS.md row-count and SHA preflight"
        status: pass
    human_judgment: false

duration: 3h 32min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 12: Planning Receipt Retirement Summary

**Active contracts now validate live row-focus, accessibility, motion, CI, and repository behavior while ten completed executable receipts are removed with exact full-SHA recovery identities.**

## Performance

- **Duration:** 3h 32min
- **Started:** 2026-09-11T05:14:54Z
- **Completed:** 2026-09-11T08:47:28Z
- **Tasks:** 2
- **Files modified:** 18 production, test, and planning files

## Accomplishments

- Built a synthetic-first planning dependency scanner that reports the operation, planning path, file, and line, then activated it over tracked ExUnit, Mix, and CI source classes derived from `git ls-files`.
- Removed historical audit and motion-inventory receipt checks while preserving the exact live row-history focus/dialog assertions and tokenized animation, transition, and reduced-motion contracts.
- Preflighted and removed exactly eight completed test contracts and two Phase-198 verifier scripts; recorded ten purpose/last-use/supersession/full-SHA recovery rows.
- Migrated three additional historical-read surfaces to retain their live CI recorder, workflow, and repository hygiene invariants without reading private planning prose.

## Task Commits

1. **Task 1 RED: failing planning dependency scanner contract** — `f575cabf` (test)
2. **Task 1 GREEN: live row/motion contracts and scanner core** — `a9407072` (feat)
3. **Task 2: exact executable receipt retirement and live scan** — `cd67b388` (chore)

## TDD Gate Compliance

- **RED:** `mix test test/threadline/planning_dependency_contract_test.exs --seed 0 --max-failures 1` exited 2 because the named planning-backed `File.read!` assertion expected one violation and the unimplemented scanner returned `[]`.
- **Evidence gate:** `gsd_run check tdd-red-evidence /tmp/threadline-199-12-task1-red-evidence.json --raw` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** the focused Task-1 suite passed 56 tests, 0 failures; the automatic tracer feedback rerun also passed 56 tests, 0 failures.
- **REFACTOR:** no separate refactor commit was needed; implementation remained narrow after GREEN.

## Files Created/Modified

- `test/threadline/planning_dependency_contract_test.exs` — injected-source scanner, file/line violations, benign-prose control, Git-derived active source set, and live assertion.
- `test/threadline/row_history_focus_evidence_contract_test.exs` — retains red control, bounded prover, Playwright policy, dialog semantics, focus visibility, and overflow checks; removes only the historical audit receipt.
- `test/threadline/operator_surface/style_contract_test.exs` — keeps live motion tokens, animation consumers, transitions, and accessibility behavior without the archived motion inventory.
- `.planning/phases/199-decouple/199-RETIRED-CONTRACTS.md` — exact ten-row purpose, last-use, supersession, and full-SHA recovery register.
- `test/threadline/ci_attestation_contract_test.exs` — retains executable recorder safety and atomic replacement tests without Phase-198 planning-prose replay.
- `test/threadline/phase06_nyquist_ci_contract_test.exs` — retains live workflow, local-parity, README, CONTRIBUTING, and topology assertions without archived verification-document checks.
- `test/threadline/removed_artifact_contract_test.exs` — retains tracked-target, root-executable, and public-document citation scanning without reading planning authority/history files.
- Ten retired paths listed in the frontmatter were intentionally deleted after tracked/consumer/history and recovery-SHA preflight.

## Decisions Made

- The scanner derives active source files from Git rather than maintaining a filename allowlist. Its only source exclusion is its own file, which contains the deliberate forbidden synthetic control.
- Planning-history reads and D-01 operator evidence fixture reads have distinct ownership. This plan blocks executable receipt/history coupling; the Phase-199 fixture migration moves the five load-bearing evidence roots before the final planning-absent aggregate.
- Historical CI attestations remain durable evidence, but their completed planning-prose joins no longer execute on every default test run. The live recorder safety contract remains active.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Migrated three additional planning-history readers**

- **Found during:** Task 2 live source activation
- **Issue:** `ci_attestation_contract_test.exs`, `phase06_nyquist_ci_contract_test.exs`, and `removed_artifact_contract_test.exs` still read completed planning prose and had no later Phase-199 plan owner, preventing planning-independent default tests.
- **Fix:** Removed only completed receipt/prose assertions and planning document inputs while retaining their live recorder, workflow, documentation, tracked-artifact, and mutation contracts.
- **Files modified:** `test/threadline/ci_attestation_contract_test.exs`, `test/threadline/phase06_nyquist_ci_contract_test.exs`, `test/threadline/removed_artifact_contract_test.exs`
- **Commit:** `cd67b388`

**2. [Rule 3 - Blocking Issue] Replaced unsupported `mix test -x` shorthand**

- **Found during:** Task 1 verification
- **Issue:** Mix 1.19.5 rejects `-x` as an unknown option.
- **Fix:** Used the supported equivalent `--max-failures 1` for focused fail-fast verification.
- **Files modified:** None
- **Commit:** N/A (verification-command adjustment only)

## Deferred Issues

- `mix verify.test` ran 1,498 tests and passed 1,497, with one pre-existing failure in `Threadline.OperatorSurface.RefutePartitionTest`. Plan 199-01 made `:mechanical_floors` explicit, while this test still calls `MechanicalChecker.run(scorecard_dir: tmp_dir)`. Plan 199-02 explicitly owns `refute_partition_test.exs` and depends on Plan 199-01; the handoff is recorded in `.planning/phases/199-decouple/deferred-items.md`.

## Authentication Gates

None.

## Known Stubs

None.

## Verification

- Task 1 focused suite: 56 tests, 0 failures.
- Task 1 tracer feedback gate: 56 tests, 0 failures.
- Task 2 scanner/zero-skip/additional live-contract suite: 24 tests, 0 failures.
- Inventory check: exactly 10 retirement rows and exactly 10 committed deletions.
- Remaining historical-path matches in active source are diagnostic strings/comments only; the live scanner reports zero executable violations.
- Full default suite: 1,498 tests, 1 pre-existing Plan-199-02-owned failure; no Plan-199-12 test failed.

## Next Phase Readiness

- Plans 199-02 through 199-08 can migrate the D-01 operator evidence corpus without Phase-198 executable receipts remaining in the default suite.
- Plan 199-14 can reuse the live scanner and run the final disposable-clone aggregate with `.planning` physically absent.

## Self-Check: PASSED

- Confirmed the scanner, recovery inventory, and summary exist.
- Confirmed Task commits `f575cabf`, `a9407072`, and `cd67b388` exist.
- Confirmed all ten authorized retired paths are absent, exactly ten deletions are committed, and exactly ten recovery rows are present.
