---
phase: 248-reconcile-the-base-and-safety-proof-ownership
plan: "03"
subsystem: dependencies
tags: [elixir, mix, ecto, phoenix-html, bandit, hex-advisories]
requires:
  - phase: 248-02
    provides: Reconciled candidate and advisory remediation evidence ownership
provides:
  - Mix-generated patched root, bench and example lock graphs
  - Complete current all-lock advisory and compatibility proof
affects: [248-04]
actuals:
  tokens: 4283
  tasks: 2
  commits: 2
  plan_head_before: ad8ac45be26be7b284c1807ca21f4c76ff4b60dc
  plan_head_after: cfe25f337007dfc9b9e8a3de7be67ea0ce073ade
tech-stack:
  added: []
  patterns: [Targeted Mix unlock and dependency resolution for transitive packages]
key-files:
  created:
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-ADVISORY-PROOF.md
    - .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-03-SUMMARY.md
  modified:
    - mix.lock
    - bench/mix.lock
    - examples/threadline_phoenix/mix.lock
key-decisions:
  - "Use Mix unlock/get for transitive Ecto entries; retain only Mix-generated checksums and metadata."
  - "Treat declared Elixir requirements as minimum metadata compatibility evidence; current-toolchain compilation does not establish a minimum-toolchain run."
  - "Keep the scheduled clean dependency-health receipt and live issue #61 state pending; local audit evidence does not close the issue."
requirements-completed: [ADM-03]
coverage:
  - id: D1
    description: Root Ecto and Phoenix.HTML advisories are resolved in-range and the root graph compiles.
    requirement: ADM-03
    verification:
      - kind: other
        ref: mix compile --warnings-as-errors
        status: pass
      - kind: other
        ref: mix verify.deps_audit
        status: pass
    human_judgment: false
  - id: D2
    description: Bench and example lock advisories are resolved and the full audit policy remains intact.
    requirement: ADM-03
    verification:
      - kind: other
        ref: mix verify.deps_audit
        status: pass
      - kind: unit
        ref: test/threadline/deps_audit_contract_test.exs and test/threadline/deps_audit_gate_test.exs
        status: pass
    human_judgment: false
  - id: D3
    description: The proof records lock identities, collateral review, compatibility limits, all findings and the live receipt boundary.
    verification:
      - kind: other
        ref: .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-ADVISORY-PROOF.md
        status: pass
    human_judgment: false
duration: 21min
completed: 2026-11-11
status: complete
---

# Phase 248 Plan 03: Compatible Advisory Lock Remediation Summary

**Ecto 3.14.3, Phoenix.HTML 4.4.0 and Bandit 1.14.1 resolved in the existing root, bench and example locks, with a clean current all-lock audit.**

## Performance

- **Duration:** 21 min
- **Started:** 2026-11-11T02:32:24Z
- **Completed:** 2026-11-11T02:54:13Z
- **Tasks:** 2
- **Files modified:** 5

## Accomplishments

- Updated only the six approved lock tuples across the three existing locks using Mix resolution; all collateral lock entries were reviewed and none changed.
- Cleared all findings from root, bench and example in the final tiered audit, and passed the existing audit contracts.
- Recorded source identities, generated lock identities, compatibility evidence, full interim findings, final checks and the live issue receipt boundary in [248-ADVISORY-PROOF.md](248-ADVISORY-PROOF.md).

## Task Commits

Each task was committed atomically:

1. **Task 1: Resolve root dependency advisories** — 7c96f4c2f672d712d7a20b4272133ebcbf45d38b (chore)
2. **Task 2: Resolve bench and example advisories** — cfe25f337007dfc9b9e8a3de7be67ea0ce073ade (chore)

Plan metadata is committed with this summary; its commit is reported in the plan completion record.

## Files Created/Modified

- .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-ADVISORY-PROOF.md — complete advisory evidence and compatibility limits.
- mix.lock — Ecto 3.14.3 and Phoenix.HTML 4.4.0.
- bench/mix.lock — Ecto 3.14.3.
- examples/threadline_phoenix/mix.lock — Ecto 3.14.3, Phoenix.HTML 4.4.0 and Bandit 1.14.1.
- .planning/phases/248-reconcile-the-base-and-safety-proof-ownership/248-03-SUMMARY.md — execution results and traceability.

## Verification

- mix compile --warnings-as-errors — exit 0 on Elixir 1.17.3 / OTP 27.3.4.15. Two warnings were printed from unchanged Phoenix 1.8.13 dependency code; the command succeeded. No minimum-toolchain build was performed.
- mix verify.deps_audit — exit 0; three lockfiles audited and zero reported findings, including non-blocking tiers.
- mix test test/threadline/deps_audit_contract_test.exs test/threadline/deps_audit_gate_test.exs — exit 0; 86 tests, 0 failures.
- The patched package metadata declares Elixir requirements compatible with the project floor Elixir 1.15.8 / OTP 26.2.5.21. This metadata review is not a minimum-runtime test.
- No full bench/example suite, browser check or ci.all run was duplicated; Plan 248-04 owns assembled-candidate proof.

## Decisions Made

- Ecto is transitive in these Mix projects. After the root direct update attempt reported that Ecto was not a direct dependency, the locks were resolved through targeted unlock/get and direct-dependency updates. Mix generated all checksums; no lock metadata was fabricated.
- The advisory tiers and policy implementation remained unchanged. A clean local audit is recorded as local evidence only; it does not satisfy a scheduled live receipt.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Resolve transitive Ecto entries through Mix unlock/get**

- **Found during:** Task 1 (root dependency resolution)
- **Issue:** The planned direct Ecto update failed because Ecto is transitive and not a direct project dependency; an incomplete intermediate lock entry was not accepted.
- **Fix:** Used Mix targeted unlock/get for the transitive Ecto entry and updated declared direct dependencies where appropriate. Mix regenerated valid package metadata and checksums.
- **Files modified:** mix.lock, bench/mix.lock, examples/threadline_phoenix/mix.lock
- **Verification:** All three locks contain Ecto 3.14.3; final all-lock audit and audit policy tests passed.
- **Committed in:** 7c96f4c2 and cfe25f33.

**Total deviations:** 1 auto-fixed (Rule 3). **Impact:** Required to resolve a transitive package with Mix; no declarations, support floors or unrelated lock entries changed.

## Issues Encountered

The first root command for Ecto exited because Mix does not update a transitive package through the direct dependency update form. The supported targeted unlock/get path produced the valid lock entry. Compilation printed two warnings from unchanged Phoenix dependency code while exiting successfully.

## Next Phase Readiness

Plan 248-03 local acceptance is complete and ready for Plan 248-04's assembled bench/example/browser/canonical checks. The scheduled clean dependency-health receipt and issue #61 closure remain outstanding live receipts; neither is claimed here or changed by this plan.

## Self-Check: PASSED

- The proof artifact and all three lockfiles exist in the verified worktree.
- Both task commits are present on this branch, confirmed by the plan evaluation-scope check.
- Final audit, compile and policy-contract verification results are recorded above and in the proof artifact.

---
*Phase: 248-reconcile-the-base-and-safety-proof-ownership*
*Completed: 2026-11-11*
