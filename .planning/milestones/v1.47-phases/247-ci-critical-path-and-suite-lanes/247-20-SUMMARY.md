---
phase: 247-ci-critical-path-and-suite-lanes
plan: 20
subsystem: testing
tags: [elixir, exunit, docker, timing, otp, local-canary]
requires:
  - phase: 247-18
    provides: completed landing dependency and frozen phase acceptance boundaries
provides:
  - Dependency-free exact-runtime ExUnit boundary probe and fail-closed receipt verifier
  - Immutable preflight failure and actual INVALID warmup receipt with a report projection
affects: [247-21, CI-02, CI-03]
actuals:
  tokens: 17432
  tasks: 2
  commits: 6
  plan_head_before: 120cf53ab61da052b64aef3b7113fdb4581100cc
  plan_head_after: 662f9921608da2b4fce6a5614e0ff9c1e7ab1e68
tech-stack:
  added: []
  patterns:
    - Standard-library Python coordinates a private, bounded Docker child.
    - Monotonic per-child events and VM-relative formatter timings remain separate.
key-files:
  created:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py
    - .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_case.exs
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY-PREFLIGHT.json
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.md
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-20-SUMMARY.md
  modified:
    - .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json
key-decisions:
  - "Classify a child that emitted negative monotonic timestamps but lacked a valid registration/event record as INVALID, not VALID_NO_SIGNAL."
  - "Keep the original zero-event Docker preflight receipt immutable and link the corrected run to its SHA-256."
  - "Keep historical CI causality UNPROVEN and leave CI-02 INCOMPLETE and CI-03 MISS."
patterns-established:
  - "An invalid local measurement is a complete bounded outcome only when every attempted arm and its stop reason are retained."
requirements-completed: [CI-02, CI-03]
coverage:
  - id: D1
    description: "Dependency-free exact-runtime canary coordinator, runner, and fixed-budget receipt validator"
    requirement: CI-03
    verification:
      - kind: other
        ref: "python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --self-test"
        status: pass
    human_judgment: true
    rationale: "The actual arm exposed a negative monotonic timestamp parser defect and no valid timing result; this artifact needs follow-up before another measurement can use it."
  - id: D2
    description: "Raw canary and preflight receipts preserve all attempted-arm metadata, image/source identity, and typed INVALID status"
    requirement: CI-02
    verification:
      - kind: integration
        ref: "python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json"
        status: pass
    human_judgment: false
  - id: D3
    description: "Readable report mirrors the raw receipt and separates local validity from historical CI gates"
    verification:
      - kind: integration
        ref: "python3 -B .planning/phases/247-ci-critical-path-and-suite-lanes/tools/exunit_boundary_probe.py --verify .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.json --report .planning/phases/247-ci-critical-path-and-suite-lanes/247-LOCAL-CANARY.md"
        status: pass
    human_judgment: false
duration: "about 25 min; exact start timestamp was not captured"
completed: 2026-10-27
status: complete
---

# Phase 247 Plan 20: Local ExUnit boundary canary Summary

**An exact Elixir 1.15.8 / OTP 26.2.5.21 canary stopped INVALID after one warmup exposed a negative-monotonic timestamp parser defect; historical CI causality remains unproven.**

## Performance

- **Duration:** About 25 minutes; the exact start timestamp was not captured.
- **Started:** Not captured. The first recorded timestamp during execution was 2026-10-27T13:36:30Z.
- **Completed:** 2026-10-27.
- **Tasks:** 2 completed, including the explicitly permitted invalid-measurement stop.
- **Files modified:** 6 plan artifacts, including this summary and the preserved preflight receipt.
- **Measured commits:** 6 from the persisted plan ledger. Five are executor-owned commits listed below; the range also includes parent-owned protocol clarification commit `34a4b011`.

## Accomplishments

- Added a dependency-free Python coordinator and standalone ExUnit runner. The coordinator defines at most two warmups, three alternating pairs, two controls, 15 seconds per child, and 150 seconds overall; it pins the cached image by immutable ID and records per-child runtime, source, formatter, and canary provenance.
- Corrected the pre-data Docker mount syntax before the actual observation series. The original zero-event failure is preserved byte-for-byte at `247-LOCAL-CANARY-PREFLIGHT.json`, SHA-256 `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`.
- Recorded the actual series as `INVALID`: one async warmup launched on Elixir `1.15.8`, OTP `26.2.5.21`, ARM64; no A/B pair or control ran. The child emitted events, but negative monotonic values failed the parser and the registration event was absent. No observed arm was replaced.
- Produced a readable report whose machine projection matches the raw receipt. The historical CI cause remains `UNPROVEN`; CI-02 remains `INCOMPLETE`, and CI-03 remains `MISS`.

## Provenance and Verification

- Image ID: `sha256:34238960354603d7bbe04d55c0c67a5c9b03e1366f3511614ca6357d74a6650b`
- Image digest: `hexpm/elixir@sha256:bcead3678dec8be86c3d8b93236e4b9c685f2a30472e71aeb972a834ef05b5fb`
- Copied unchanged `PartitionMonitor` SHA-256: `3164124276f674842be3d4515eb94a063969a7054f7716b655d206fefbbe2aa4`
- Elixir runner SHA-256: `e42f640c715af972265d55f6c81ead5f0d2512da73210c9b9ca9d32289f50a57`
- Producer commit: `07d6a2c3805f1aaa728dc0c28367f56afca6e9f8`; coordinator SHA-256 at that commit: `60f8ee458e0104ac105abc0edb3fc211ff871b06ae64e671d5fc7c9d72ac9b4b`.
- Pure `--self-test` passed before the actual series, rejecting 11 synthetic receipt mutations. Corrected Docker flags passed a metadata-only `elixir --version` precondition. The actual receipt and report projection passed `--verify`; `git diff --check` passed.
- No full suite, production test, database, hosted CI, package install, push, or publication ran.

## Task Commits

1. **Task 1: Probe tools and first preflight receipt** — `d2ccaf14` (`feat`)
2. **Task 2: Initial interpretation report** — `d31668b8` (`docs`)
3. **Pre-data repair and immutable preflight receipt** — `07d6a2c3` (`fix`)
4. **Task 2: Actual invalid observation and report** — `7b835bf1` (`docs`)
5. **Task 2: Producer hash lineage and limitations** — `662f9921` (`docs`)

**Plan metadata:** to be committed after this summary is self-checked.

## Files Created/Modified

- `tools/exunit_boundary_probe.py` — Python standard-library coordinator, fixed schedule, Docker ownership/limits, receipt verifier, and synthetic self-tests.
- `tools/exunit_boundary_case.exs` — standalone runtime/version guard, scoped registration trace, barrier runner, and event formatter.
- `247-LOCAL-CANARY-PREFLIGHT.json` — byte-identical preservation of the first Docker syntax failure.
- `247-LOCAL-CANARY.json` — actual-series receipt with one attempted warmup, typed `INVALID`, bounded output, and the immutable preflight pointer/hash.
- `247-LOCAL-CANARY.md` — measured outcome, limits, history, and verifier-checked projection.

## Decisions Made

- Negative values from `System.monotonic_time/1` are valid OTP monotonic timestamps. The parser's unsigned-only check invalidated the event stream; the receipt therefore remains `INVALID`, not a semantic result or a no-signal result.
- The first Docker `125` was a pre-data CLI syntax failure (`--mount ...dst=/probe,rw`). Removing `,rw` and validating the corrected flags with `elixir --version` was the sole pre-data repair; the original receipt remains preserved.
- The actual arm reached ExUnit and produced an invalid observation. The fixed cap therefore ended the canary immediately, with zero replacement arms, pairs, or controls.
- Local runtime semantics, historical AMD64 CI causality, and phase acceptance remain separate verdicts.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Repaired invalid Docker bind-mount syntax before measurements**
- **Found during:** Task 1 preflight.
- **Issue:** Docker rejected the `rw` suffix after the bind mount destination, exiting `125` before launching the Elixir runtime.
- **Fix:** Removed `,rw`, used the owned private temp mount, and added bounded sanitized stdout/stderr capture for child results.
- **Files modified:** `tools/exunit_boundary_probe.py`, `247-LOCAL-CANARY-PREFLIGHT.json`, `247-LOCAL-CANARY.md`.
- **Verification:** Metadata-only exact-image `elixir --version` passed with the corrected flags; 11 pure negative receipt mutations were rejected.
- **Committed in:** `07d6a2c3`.

### Deferred Issues

- The event parser only accepts unsigned timestamp text. OTP's monotonic clock emitted negative values, causing `ValueError: malformed event record`. Raw ordering is qualitatively consistent with a module starting during require, but missing registration tracing and controls preclude `VALID_SEMANTIC`. The actual run was stopped and not retried under the fixed one-series cap. The original producer commit and coordinator hash are recorded for a separately reviewed offline parser correction; the current verifier does not bind that Python hash to the file/commit automatically.
- The generic parser-exception handler overwrote the child's captured stderr with the parser exception string. The stdout is preserved; original process stderr is unrecoverable for this arm. This defect is reported for follow-up and was not changed after the observed invalidity.

**Total deviations:** 1 pre-data auto-fix; 2 observed tooling defects deferred under the no-retry stop rule. **Impact:** The tool and report preserve an honest invalid outcome; no historical cause or acceptance claim was promoted.

## Issues Encountered

- Actual schedule consumed: 1 of at most 2 warmups, 0 of 6 pair arms, 0 of 2 controls. Overall receipt time was 2,578 ms; child exit was `0`. The raw stdout contains the exact runtime line and event timestamps. No parsed formatter timing was retained.
- The report's `stderr_excerpt` field records `malformed event record`, which is the coordinator exception after overwriting the already-captured child stderr. The true child stderr cannot be recovered.
- `.planning/STATE.md` was already modified by the parent before execution and remains untouched and unstaged. State, roadmap, and requirement tracking updates are parent-owned for this dispatch.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 20's bounded diagnostic is complete with an honest `INVALID` result. Its artifacts are ready for review.
- Plan 21 may independently replay frozen CI evidence. It must preserve this invalid canary result and must not infer historical causality from it.
- CI-02 remains `INCOMPLETE`; CI-03 remains `MISS`. No CI workflow or acceptance state changed.

## Self-Check: PASSED

- All six plan artifacts exist, including the immutable preflight receipt.
- Task commits `d2ccaf14`, `d31668b8`, `07d6a2c3`, `7b835bf1`, and `662f9921` are ancestors of HEAD.
- The actual receipt/report projection verifier passes with status `INVALID` and one attempted warmup.
- The preflight receipt SHA-256 remains `728d8c8efa6fd88c6124c0c1745bcd0a26b00c4b61ebbcd25c7135aa607bb553`.

---
*Phase: 247-ci-critical-path-and-suite-lanes*
*Completed: 2026-10-27*
