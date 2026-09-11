---
phase: 199-decouple
plan: "20"
subsystem: static-analysis
tags: [dialyzer, exact-ratchet, source-owned-evidence, tdd]

requires:
  - phase: 199-13
    provides: "Immutable 40-warning first-run ledger and sealed raw-output provenance"
  - phase: 199-15
    provides: "Source-owned critic/tooling fixture and slice verifier"
  - phase: 199-16
    provides: "Fixed query/storage fixture partition"
  - phase: 199-17
    provides: "Fixed export/investigation fixture partition"
  - phase: 199-18
    provides: "Fixed operator-boundary fixture partition"
  - phase: 199-19
    provides: "Fixed operator-LiveView fixture partition"
provides:
  - "Planning-independent exact partition of W01-W40 across 22 disjoint warning origins"
  - "Zero-ceiling Dialyzer ignore ratchet with fail-closed mutation controls"
  - "Green full-suite and full optional-app strict-Dialyzer evidence for CI handoff"
affects: [199-14, DECOUPLE-07, DECOUPLE-08]

actuals:
  tokens: 5894
  tasks: 2
  commits: 3
plan_head_before: 46c7370e0ee24bf172669be5752bdd1099d98763

tech-stack:
  added: []
  patterns:
    - "Source-owned JSON fixtures are joined into one exact, disjoint analyzer evidence partition"
    - "Ignore entries must be literal fixture-backed tuples with immediately adjacent actionable comments"
    - "A committed zero ceiling can decrease but never increase"

key-files:
  created:
    - test/fixtures/dialyzer/README.md
  modified:
    - test/threadline/dialyzer_ignore_contract_test.exs

key-decisions:
  - "Keep .dialyzer_ignore.exs empty and commit the ceiling at zero because every sealed warning is fixed."
  - "Use only the five source fixtures as historical authority; the executable contract reads no planning artifact."
  - "Treat any unsealed warning, origin drift, broad suppression, or unused filter as a fail-closed condition rather than expanding source authority."

patterns-established:
  - "Analyzer cleanup closes with an exact global fixture join, synthetic negative controls, and a live unused-filter gate."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "The five fixtures partition W01-W40 exactly across 22 distinct, slice-disjoint origins."
    requirement: DECOUPLE-08
    verification:
      - kind: integration
        ref: "dialyzer_slice_contract_test.exs plus dialyzer_ignore_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "Fixed warnings have no filters; broad, malformed, duplicate, unknown, stale, uncommented, and over-ceiling residue fails closed."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "dialyzer_ignore_contract_test.exs mutation controls"
        status: pass
    human_judgment: false
  - id: D3
    description: "The full application test suite and complete optional-app strict analyzer are green."
    requirement: DECOUPLE-08
    verification:
      - kind: integration
        ref: "mix test --max-failures 1 && mix dialyzer --list-unused-filters"
        status: pass
    human_judgment: false

duration: 17 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 20: Exact Dialyzer Ratchet and Full Analyzer Proof Summary

**All forty sealed warnings now resolve through a planning-independent, zero-suppression source contract, with the full test suite and complete strict optional-app analyzer green.**

## Performance

- **Duration:** 17 min
- **Started:** 2026-09-11T19:31:05Z
- **Completed:** 2026-09-11T19:48:08Z
- **Tasks:** 2
- **Implementation files modified:** 2

## Accomplishments

- Replaced the planning-dependent, obsolete 14-origin contract with an exact source-owned join over all five fixtures: `3 + 10 + 15 + 7 + 5 = 40` warnings and 22 distinct origins.
- Kept `.dialyzer_ignore.exs` empty and the committed ceiling at zero because all W01-W40 records are fixed.
- Added fail-closed controls for regex/glob filters, non-tuple and helper entries, duplicates, missing comments, missing rationale/removal triggers, fixed and unknown warnings, missing origins, unused filters, and ceiling increases.
- Documented fixture provenance, deterministic maintenance commands, the decrease-only ceiling policy, and the distinction between local available-PLT proof and Plan 199-14's CI cold-build measurement.
- Proved all five bounded slices, 1,526 repository tests, and the complete strict Dialyzer run green without editing any warning-origin source file.

## Task Commits

1. **Task 1 RED: expose incomplete partition and broad-filter acceptance** — `760e0353` (test)
2. **Task 1 GREEN: enforce the exact source-owned partition and zero ignore ratchet** — `f6a607cf` (feat)
3. **Task 2: document the verified strict analyzer handoff** — `78ddfae7` (docs)

## TDD Gate Compliance

- **Exact-partition RED:** a named contract joined the five fixtures and intentionally failed because the old test still contained a runtime planning-path dependency. `/tmp/threadline-199-20-task1-partition-red-evidence.json` classified the failure as `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Ignore-ratchet RED:** a named contract intentionally failed because the old validator accepted `lib/**/*.ex`. `/tmp/threadline-199-20-task1-ratchet-red-evidence.json` classified the failure as `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **GREEN:** the combined slice/global suite passed 18 tests, and `mix dialyzer --no-check --list-unused-filters` reported zero errors, skipped filters, and unnecessary filters.
- **Tracer feedback gate:** the same 18-test and unused-filter sequence passed again after commit `f6a607cf` before expansion to Task 2.
- **REFACTOR:** no separate refactor commit was required; GREEN already used one deterministic validator with small fixture/control helpers.
- **Commit order:** `test → feat → docs`.

## Verification

- Five `bin/verify-dialyzer-slice --fixture ...` preconditions — **PASS**: `3 + 10 + 15 + 7 + 5 = 40` sealed warnings, `3 + 5 + 5 + 4 + 5 = 22` authorized origins, zero live warnings in every slice.
- `mix test test/threadline/dialyzer_slice_contract_test.exs test/threadline/dialyzer_ignore_contract_test.exs --max-failures 1` — **PASS**, 18 tests, 0 failures.
- `mix test --max-failures 1` at final HEAD — **PASS**, 1,526 tests, 0 failures, 1 excluded.
- `mix dialyzer --list-unused-filters` at final HEAD — **PASS**, `Total errors: 0, Skipped: 0, Unnecessary Skips: 0`.
- `.dialyzer_ignore.exs` — **PASS**, literal empty list with a ceiling of zero; no fixed warning gained a filter.
- Runtime planning-dependency scan — **PASS**, the global contract constructs the planning-directory sentinel dynamically and contains no planning path literal.
- Current-plan implementation diff — **PASS**, only the source-owned contract and fixture README changed; no warning-origin source file changed.

## Full Analyzer Evidence

- **Command:** `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.19.5-otp-27 mix dialyzer --list-unused-filters`
- **Toolchain:** Erlang/OTP 27.3.4.15; Elixir 1.19.5-otp-27; Dialyxir 1.4.8.
- **PLT:** `.dialyzer/dialyxir_erlang-27.3.4.15_elixir-1.19.5_deps-dev.plt`, reported up to date.
- **Required additions:** Mix, ExUnit, Phoenix, Phoenix LiveView, Phoenix HTML, Phoenix PubSub, Oban, ExAws, ExAws S3, Hackney, and SweetXml were present.
- **Strict classes:** `unknown`, `unmatched_returns`, and `extra_return` remained enabled.
- **Result:** zero warnings, zero filters, zero unused filters.
- **Captured output SHA-256:** `78b6381fec199a27790a7e601ad9d5b5a0e49a6dd25dd03498f27994ec3446fe`.
- **Local available-PLT measurement:** 2.83 seconds elapsed; 1,149,353,984-byte maximum resident set size reported by `/usr/bin/time -l`.
- **CI boundary:** this is a warm/available-PLT local proof. It is not the true CI cold-build timing/memory measurement reserved for Plan 199-14.

## Files Created/Modified

- `test/threadline/dialyzer_ignore_contract_test.exs` — exact fixture schema/provenance/partition join, AST-and-comment ignore validator, zero ceiling, strict configuration assertions, and synthetic fail-closed controls.
- `test/fixtures/dialyzer/README.md` — partition map, schema and provenance rules, exact verifier commands, decrease-only ceiling policy, and strict analyzer handoff.
- `.dialyzer_ignore.exs` — intentionally unchanged as the literal empty list `[]`.

## Decisions Made

- Zero is the only honest ignore ceiling: all forty sealed records are fixed and the full analyzer emits no warning.
- Fixed records may never acquire ignore metadata or a filter; a future irreducible record would need an exact tuple, rationale, removal trigger, and immediately adjacent comment before the contract can pass.
- Source fixtures, not historical planning prose, are the executable authority for warning IDs, origin scope, raw provenance, and disposition.
- Strict analyzer scope stays complete: no optional application or warning class was removed to obtain green output.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Pinned the established OTP 27 toolchain for slice precondition execution**

- **Found during:** Task 2 precondition
- **Issue:** The first verifier loop could not select an `elixir` executable because the unrelated untracked `.tool-versions` file does not define an active version.
- **Fix:** Re-ran the read-only precondition with the same explicit `ASDF_ERLANG_VERSION=27.3.4.15` and `ASDF_ELIXIR_VERSION=1.19.5-otp-27` environment used by the remediation plans and final analyzer.
- **Files modified:** None.
- **Verification:** All five invocations then reported their exact sealed counts and zero live warnings.
- **Commit:** Not applicable; execution-environment correction only.

---

**Total deviations:** 1 auto-fixed blocking execution-environment issue.
**Impact on plan:** Product and analyzer scope are unchanged; the explicit environment makes the intended pinned toolchain reproducible without touching the user's untracked file.

## Issues Encountered

None. The two inherited full-suite contract failures documented by earlier remediation summaries were resolved by the exact partition/ratchet implementation; the final suite is green.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The scan found only non-empty validation guards in the test helper; this plan introduced no placeholder implementation, skipped test, or unwired data path.

## Threat Flags

None. The changes add no endpoint, authentication path, file-access trust boundary, schema change, or production execution surface.

## Next Phase Readiness

- Plan 199-14 can consume a green, planning-independent strict-analyzer prerequisite.
- All forty sealed warnings are accounted for across exactly 22 disjoint origins, with zero surviving residue and no suppression debt.
- CI cold-build timing and memory remain explicitly owned by Plan 199-14; local metrics here must not be substituted for that evidence.

## Self-Check: PASSED

- The source contract, fixture README, unchanged ignore file, and summary exist on disk.
- All three task commit hashes resolve in Git.
- Both persisted RED evidence records exist and classified as `RED_EVIDENCE_OK`.
- The fixture union independently reports 40 warnings, 22 origins, 40 unique IDs, 22 unique origins, and only `fixed` dispositions.
- The committed ignore file normalizes to the literal empty list `[]`.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
