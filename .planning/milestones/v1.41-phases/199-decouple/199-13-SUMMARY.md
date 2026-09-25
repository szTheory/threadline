---
phase: 199-decouple
plan: "13"
subsystem: static-analysis
tags: [dialyxir, dialyzer, plt, triage, tdd, safety-gate]
requires:
  - phase: 199-08
    provides: Planning-independent fixture ownership and full optional-app build inputs
provides:
  - Reproducible full optional-app Dialyxir configuration and PLT
  - Immutable 40-warning first-run ledger with a sealed 22-file origin set
  - Executable 14-file ceiling with a 15-path positive control
affects: [199-replan, 199-14, 203-architecture, dialyzer]
actuals:
  tokens: 4214
  tasks: 0
  commits: 3
plan_head_before: ad9c55a13d5c4637434672277446e504b0ed4b1e
tech-stack:
  added: [dialyxir 1.4.8, erlex 0.2.9]
  patterns: [sealed raw-analysis receipt, fail-closed warning-origin scope cap]
key-files:
  created:
    - .dialyzer_ignore.exs
    - test/threadline/dialyzer_ignore_contract_test.exs
    - .planning/phases/199-decouple/199-DIALYZER-TRIAGE.md
  modified:
    - mix.exs
    - mix.lock
key-decisions:
  - "The measured 22-file warning-origin set exceeds the plan's 14-file authority, so Plan 199-13 halts before all source fixes and suppressions."
  - "The empty ignore file is intentional: the halted plan approves zero suppressions and establishes no ignore ceiling."
patterns-established:
  - "Seal before edit: hash the first analyzer output and enumerate every exact warning origin before touching warning-producing source."
  - "Scope cap: accept at most 14 distinct exact paths and make a fifteenth path fail mechanically."
requirements-completed: []
coverage:
  - id: D1
    description: "The first full optional-app analysis is reproducible and every raw warning occurrence is recorded."
    requirement: DECOUPLE-07
    verification:
      - kind: integration
        ref: ".planning/phases/199-decouple/199-DIALYZER-TRIAGE.md#complete-raw-warning-ledger"
        status: pass
    human_judgment: false
  - id: D2
    description: "Dialyzer is green with a strict, tighten-only ignore ceiling."
    requirement: DECOUPLE-08
    verification:
      - kind: integration
        ref: "mix test test/threadline/dialyzer_ignore_contract_test.exs --max-failures 1"
        status: fail
      - kind: integration
        ref: "mix dialyzer"
        status: fail
    human_judgment: false
duration: 8 min
completed: 2026-09-11
status: halted
---

# Phase 199 Plan 13: Dialyzer Bootstrap and Ratchet Summary

**The first full optional-app analysis is sealed at 40 warnings across 22 source files, intentionally tripping the plan's 14-file re-planning gate before any warning-origin edit or suppression.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-09-11T15:32:55Z
- **Stopped:** 2026-09-11T15:40:56Z
- **Tasks completed:** 0 of 2
- **Files modified:** 5

## Halt Result

Plan 199-13 reached its designed hard stop during Task 1. The initial raw analysis emitted 40 warnings across 22 distinct warning-origin source files, eight above the maximum authority of 14. Per the plan, execution stopped with zero warning-origin source edits and requires Phase 199 re-planning/re-slicing.

Task 2 did not start. No ignore entry was approved, no ceiling was guessed, and Dialyzer remains blocking/red.

## Accomplishments

- Added Dialyxir 1.4.8 as a dev/test-only, non-runtime dependency and configured all nine named optional applications plus `mix` and `ex_unit` in the full PLT.
- Preserved Dialyxir's default `unknown` warning signal and enabled `unmatched_returns` and `extra_return`.
- Sealed the exact first-run command, toolchain, configuration/lock/output digests, all 40 raw warning occurrences, and the complete sorted 22-file origin set.
- Added an executable scope contract that accepts 14 distinct exact source paths and rejects a fifteenth with an explicit re-plan/re-slice diagnostic.

## Commits

1. **Task 1 RED: failing full-build and origin-cap contract** — `e34f7798` (`test`)
2. **Task 1 halt receipt: Dialyxir config and over-cap triage** — `c34acb80` (`chore`)
3. **Task 1 contract formatting correction** — `f9c2e697` (`style`)

There is intentionally no GREEN `feat(199-13)` commit: the measured live input tripped the plan's stop condition before implementation was authorized.

## Files Created/Modified

- `mix.exs` — full optional-app PLT, warning flags, ignore path, and unused-filter configuration.
- `mix.lock` — locked Dialyxir 1.4.8 and erlex 0.2.9.
- `.dialyzer_ignore.exs` — intentionally empty; no warning is approved for suppression.
- `test/threadline/dialyzer_ignore_contract_test.exs` — RED config/triage contract and 15-path hard-stop positive control.
- `.planning/phases/199-decouple/199-DIALYZER-TRIAGE.md` — immutable warning ledger and halt receipt.

## TDD Gate Compliance

- **RED:** `e34f7798`; the named test failed on the missing Dialyxir dependency, and the persisted evidence classifier returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Live gate:** after configuration and analysis, the same named test fails on the intended `22 <= 14` assertion; the separate 15-path positive control passes.
- **GREEN:** intentionally absent because the plan's fail-closed scope gate forbids proceeding.
- **REFACTOR:** not applicable.

## Decisions Made

- Treated the 22-file live result as authoritative. The executor did not reinterpret the cap, collapse paths by subsystem, or discount architectural/unknown warnings.
- Kept the ignore list empty. A broad snapshot, file/class/regex ignore, estimated ceiling, or untriaged Phase-203 waiver would violate D-23 through D-27.
- Preserved the reproducible analyzer configuration and triage receipt so the replacement plan can split from measured evidence rather than rerun an unsealed discovery.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced the unsupported focused-test `-x` option**

- **Found during:** Task 1 RED verification
- **Issue:** Installed Mix does not support the plan's trailing `-x` option.
- **Fix:** Used the supported `--max-failures 1` fail-fast option while preserving the exact target test.
- **Files modified:** None.
- **Verification:** Two tests were discovered; the named assertion failed and the 15-path positive control passed.
- **Committed in:** No source change required.

**2. [Rule 1 - Bug] Formatted the RED contract after the pre-commit check exposed drift**

- **Found during:** Task 1 halt-receipt verification
- **Issue:** The initial RED test commit did not satisfy the repository formatter.
- **Fix:** Applied `mix format` only to the contract without changing its behavior.
- **Files modified:** `test/threadline/dialyzer_ignore_contract_test.exs`
- **Verification:** `mix format --check-formatted` passes and the test still fails exclusively at the intended 22-versus-14 gate.
- **Committed in:** `f9c2e697`

---

**Total deviations:** 2 auto-fixed (1 blocking command correction, 1 formatting bug).
**Impact on plan:** Neither adjustment changed the warning set, source scope, stop threshold, or zero-edit guarantee.

## Issues Encountered

- `mix deps.get` reported security advisories for pre-existing locked dependencies. This is out of Plan 199-13 scope and is already recorded in `deferred-items.md`.
- The strict ignore formatter rendered 29 entries because 11 repeated file/description warnings collapse. A companion raw-format run preserved all 40 individual occurrences in the ledger.

## Known Stubs

None. The empty `.dialyzer_ignore.exs` is an intentional fail-closed baseline, not a placeholder; no suppression is approved while the plan is halted.

## Threat Surface

- **T-199-25:** No suppression surface was opened; the ignore list is empty.
- **T-199-26:** First-run command, toolchain, and output/config digests are sealed in the triage artifact.
- **T-199-26A:** All 22 exact origin paths were sealed before edits, and the edit count is zero.

## Next Step

Re-plan/re-slice Phase 199 from the sealed 22-file source set. The replacement execution must retain the same raw receipt, partition fixes into reviewable scopes, and establish an ignore ceiling only after every remaining warning is individually dispositioned.

## Self-Check: PASSED

- All five changed implementation/evidence files and this summary exist.
- Commits `e34f7798`, `c34acb80`, and `f9c2e697` are present in Git history.
- The 40-row raw warning ledger and 22-path sealed origin block are non-vacuous.
- No sealed warning-origin source path has a working-tree diff.

---

*Phase: 199-decouple*
*Stopped: 2026-09-11*
