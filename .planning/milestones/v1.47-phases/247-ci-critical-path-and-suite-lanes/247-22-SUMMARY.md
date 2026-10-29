---
phase: 247-ci-critical-path-and-suite-lanes
plan: 22
subsystem: testing
tags: [elixir, exunit, docker, ci-validation, evidence]

# Dependency graph
requires:
  - phase: 247-20
    provides: Original local canary and bounded observation context.
  - phase: 247-21
    provides: Frozen descriptive replay and immutable historical evidence.
provides:
  - One authorized native ARM64 preflight and terminal one-arm validation receipt.
  - Independently reviewed report that preserves the terminal INVALID outcome and its limitations.
affects: [phase-247, ci-02, ci-03, local-validation]

# Actuals (#2632)
actuals:
  tokens: 32505
  tasks: 3
  commits: 8
commits: 8
plan_head_before: 798be0bf3a1e047ba2a2355cdda36a248de0ea43
plan_head_after: b7723a52f8df8490db72831ea53f55eca6d97323

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Keep each local observation in separate write-once preflight, receipt, and report artifacts."

key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION.reservation.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-VALIDATION.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-22-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/test_exunit_boundary_probe.py

key-decisions:
  - "Honor the explicit authorization for exactly one local series; stop after the first invalid child without retry or replacement."
  - "Keep CI-02 INCOMPLETE, CI-03 MISS, the historical AMD64 cause UNPROVEN, and Phase 247 at 2/4."

patterns-established:
  - "Separate terminal local evidence from immutable historical receipts and main-CI acceptance evidence."

requirements-completed: []
coverage:
  - id: D1
    description: "Preserve and verify the authorized local ARM64 validation as terminal INVALID after one compile-failed warmup."
    verification:
      - kind: other
        ref: "python3 -B tools/exunit_boundary_probe.py --verify 247-LOCAL-CANARY-VALIDATION.json --report 247-LOCAL-CANARY-VALIDATION.md"
        status: pass
    human_judgment: false

# Metrics
duration: 7min
completed: 2026-10-27
status: complete
---

# Phase 247 Plan 22: Local ExUnit Boundary Validation Summary

**The authorized native ARM64 validation stopped INVALID on its first warmup; the one-arm failure is recorded and CI acceptance gaps remain open.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-10-27T15:29:56Z
- **Completed:** 2026-10-27T15:36:39Z
- **Tasks:** 3/3
- **Files modified:** 11 across the complete plan, including this summary; Task 3 created four evidence artifacts.

## Accomplishments

- Recorded explicit authorization for one native ARM64 local series with one metadata/runtime preflight, at most two warmups, three A/B pairs, two controls, 15 seconds per child, 150 seconds total, and no retry or replacement.
- Preflight passed against cached image ID `sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b`, Elixir 1.15.8, and OTP 26.2.5.21.
- The one coordinator run ended `INVALID` after one async warmup exited 1 in 407 ms. Raw stderr records an internal `beam_ssa_recv:pu_is_ref_used_is/2` compiler exception. There were no runtime/event/TSV records, A/B pairs, or controls; the reservation remains consumed.
- Independent automated review confirmed the raw/report projection, exact Elixir v1.15.8 registration and runner semantics, and historical hashes. The report discloses the missing Docker container identity and that this standalone runner does not exercise `Mix.Compilers.Test`.
- The original canary, preflight, and frozen replay remain unchanged at their pinned SHA-256 values.

## Task Commits

1. **Task 1: Synthetic source-to-report plumbing and separate validation outputs** — `ff3c29c9`, `856361c4`, `6b54154d`, `181e66c8`, `1b7fe2dc`.
2. **Task 1 checkpoint record and Task 2: Explicit local scope choice** — `eec1bfad`, `8e6321f3`.
3. **Task 3: Terminal validation evidence and reviewed report** — `b7723a52`.

## Files Created/Modified

- `247-LOCAL-CANARY-VALIDATION-PREFLIGHT.json` — valid cached image/runtime preflight with source hashes.
- `247-LOCAL-CANARY-VALIDATION.json` — write-once terminal INVALID receipt with one attempted arm.
- `247-LOCAL-CANARY-VALIDATION.reservation.json` — reservation showing the single-series authorization is consumed.
- `247-LOCAL-CANARY-VALIDATION.md` — raw receipt projection, terminal interpretation, review hashes, findings, and limitations.

## Decisions Made

- Used the explicit `authorize-one-local-series` decision exactly once.
- Treated the first child compile failure as terminal. No repair, retry, replacement sample, CI dispatch, or semantic conclusion followed.
- Kept CI-02 `INCOMPLETE`, CI-03 `MISS`, historical AMD64 cause `UNPROVEN`, and Phase 247 at 2/4.

## Deviations from Plan

The committed producer did not retain an owned Docker container name or ID in the preflight or attempted-arm receipt, despite the plan requiring that identity. The report records this provenance warning. The already-consumed series was not repaired or rerun.

## Issues Encountered

- OTP's compiler failed internally while compiling `probe/runner.exs` before the script emitted runtime, ExUnit event, or formatter output. The receipt is internally verifiable as terminal `INVALID` (`--verify`: pass, one attempted arm).
- The isolated probe launches the runner directly with `elixir`; it does not invoke `mix test` or `Mix.Compilers.Test`. This receipt proves no Mix test or partition behavior.
- The independent review found no false CI or historical-cause promotion. Its sole warning is the disclosed missing container identity.

## Verification

- `python3 -B tools/exunit_boundary_probe.py --verify 247-LOCAL-CANARY-VALIDATION.json --report 247-LOCAL-CANARY-VALIDATION.md` — PASS (`INVALID; 1 attempted arms`).
- Historical receipt/replay SHA-256 checks — PASS (3/3 unchanged).
- Independent review source: `automated-review`; reviewed report body SHA-256 `f80f4d63d4b9cc104a8880a2883fb4d6abb0936bf809138467f28c3409421abe`.

## Next Phase Readiness

This plan contributes no passing semantic result. CI-02 remains INCOMPLETE because B4 has four qualifying successes and two failed exclusions, leaving its five-run median null. CI-03 remains MISS; fixed B4 first-three minimum ratios remain 1.24/1.28/1.27. B3 is training, diagnostic run `40504321590` is off main, and the historical AMD64 minimum-P3 cause remains unproven. CI-01 and CI-04 remain verified; Phase 247 remains 2/4.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*

## Self-Check: PASSED

- All four Task 3 evidence artifacts and this summary exist.
- All eight plan task commits are ancestors of the current branch.
- The terminal receipt/report verifier passes; all three historical hashes remain unchanged.

## Closeout review addendum

Canonical code review records CR-05 open (compiler-failed pinned runner), WR-04 open (container identity evidence) and inherited WR-01 deferred. Security retains two medium open controls; Nyquist is partial. Independent report re-attestation uses the exact bytes before the Independent review heading plus the complete receipt projection suffix, hash `6f6525d1490bfcb46e6f3b7be3049827e4b4cbfa557ef7027b28f69f8336eb58`. This completes the bounded execution and preserves its failed outcome; it does not satisfy a semantic or main-CI gate.
