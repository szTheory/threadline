---
phase: 247-ci-critical-path-and-suite-lanes
plan: 23
subsystem: testing
tags: [exunit, elixir, python, docker, ci-evidence]
requires:
  - phase: 247-22
    provides: consumed historical canary evidence and immutable receipt hashes
provides:
  - Full-runner compile-smoke entry point for a future pinned-runtime preflight
  - Separate write-once recheck receipt, reservation, and report contract
  - CID and inspected-name ownership checks with mocked failure controls
affects: [247-24, 247-25, ci-evidence]
tech-stack:
  added: []
  patterns: [named Elixir runner dispatch, write-once CID-bound receipts, pure mocked Docker controls]
key-files:
  created: [.planning/phases/247-ci-critical-path-and-suite-lanes/247-23-SUMMARY.md]
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py
key-decisions:
  - "The compile-smoke marker reports compile/runtime plumbing only; it never produces semantic ExUnit events or a semantic verdict."
  - "The future CLI uses --recheck-preflight, --recheck-run --preflight <receipt> --output <receipt>, and --render-report <receipt> --output <report>."
  - "A container is removable only by captured CID after inspect confirms the generated name; ambiguous ownership remains disclosed and untouched."
requirements-completed: []
actuals:
  tokens: 16869
  tasks: 2
  commits: 2
plan_head_before: c16f1e28de5da403204f6c645973e8958d4e673d
plan_head_after: 6061a1450e660f69ca4220e3da7381a38185c9d0
commits: 2
metrics:
  duration: approximately 32 minutes
  completed: 2026-10-27
status: complete
---

# Phase 247 Plan 23: Local Canary Recheck Prerequisites Summary

**A full-script compile-smoke entry point and write-once CID-bound recheck receipts now reject unowned containers in synthetic controls.**

## Performance

- **Duration:** Approximately 32 minutes; the executor start timestamp was not captured.
- **Completed:** 2026-10-27
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Moved runner dispatch into `CanaryRunner` functions and added `--compile-smoke`; normal trace and async/sync sequencing remains in the runner path.
- Added a separate recheck schema with source-bound hashes, one-shot reservation, full-runner smoke preflight, bounded arm execution, CID/name inspection, and a write-once report projection.
- Added mocked controls for compiler errors and missing markers, CID collision/missing/malformed/mismatched/reused IDs, verified-ID-only cleanup, status forgery, and report projection.
- Preserved historical verification: the Plan 22 validation receipt still verifies as `INVALID` using its original producer contract.

## Verification

- `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py` — **25 tests passed** (including review regression controls).
- `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test` — **synthetic round-trip PASS**.
- `python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION.md` — **PASS; historical receipt remains INVALID**.
- The three immutable hashes remain `7a946173a6e4c9ca407d94d766343596f77980eaf01eb0ad353985e85b171385`, `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`, and `5bbf55a8e9958e6f38d33da9ff21a816fb2b7542b03a33829ed5b881a7b8a6f1`.

All checks were pure Python or mocked. No Docker, Elixir, Mix, hosted CI, install, or new observation series was run. Therefore the changed `.exs` has **not** been compiled on the pinned Elixir 1.15.8 / OTP 26 runtime, and source-shape repair remains a hypothesis pending Plan 24 authorization and Plan 25 preflight.

## Code Review Follow-up

Committed focused fixes for the three blockers and one warning in `247-23-REVIEW.md`:

- Bind the executing coordinator bytes to the committed producer before writing the reservation and check the binding again before execution/verification.
- Require an exact affirmative decision document bound to the source candidate, schedule, and limits; stop before reservation or launch for stop markers, negation, duplicate/incidental text, or another candidate.
- Validate each completed arm immediately, stop on its first semantic/runtime/formatter/ownership failure, and bind the terminal early-stop reason to that arm's raw evidence.
- Render a verified invalid preflight into a write-once report projection that preserves the raw failure, reports zero attempted arms, and verifies through the CLI.

The new negative controls exercise changed coordinator bytes on disk, rejected decision documents with zero reservation/launch calls, a zero-exit semantically invalid first arm with exactly one child call, and invalid-preflight report round-trip plus write-once behavior. The fixes are committed as `9fae282d` (`fix(247-23): close recheck authorization and failure gaps`).

## Task Commits

1. **Task 1: Carry the complete runner through a compile-only entry point and synthetic report** — `6386577b`.
2. **Task 2: Bind new preflight and arm evidence to owned Docker identity** — `6061a145`.

## Decisions Made

- Chose explicit separate CLI modes for recheck preflight, recheck execution, and report rendering because the plan did not prescribe flags for the first two.
- Kept CI-02 **INCOMPLETE**, CI-03 **MISS**, and Phase 247 at **2/4**. This plan closes none of those evidence gaps.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Historical verifier compatibility] Kept old receipt verification bound to its recorded producer rather than current worktree bytes**
- **Found during:** Task 1
- **Issue:** The legacy preflight validator also compared old recorded sources with the changed current worktree, which prevented read-only verification of the consumed Plan 22 receipt.
- **Fix:** Removed that current-worktree comparison from historical verification. The legacy execution path still requires the committed source hashes and current commit to match before any run.
- **Files modified:** `tools/exunit_boundary_probe.py`
- **Verification:** The saved Plan 22 receipt and report verify as terminal `INVALID`; historical hashes match.
- **Committed in:** `6386577b`.

**Total deviations:** 1 correctness adjustment. No product code, CI topology, test weights, thresholds, or historical evidence changed.

## Issues Encountered

- The new preflight and recheck are deliberately not executed in this plan. The one-shot Plan 22 grant is consumed; a new scope decision belongs to Plan 24.

## Next Phase Readiness

Plan 24 can review the committed repair and decide whether to authorize the single pinned-runtime preflight. Plan 25 should use the CLI recorded above and stop on any invalid preflight or ownership record. CI-02 and CI-03 remain open.

## Self-Check: PASSED

- All three modified tools and this summary exist.
- Task commits `6386577b` and `6061a145`, and review fix commit `9fae282d`, are ancestors of the current worktree HEAD.
- The review artifact is parent-owned and remains unmodified and unstaged.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*
