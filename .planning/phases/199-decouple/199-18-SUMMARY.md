---
phase: 199-decouple
plan: "18"
subsystem: static-analysis
tags: [dialyzer, bounded-remediation, tdd, authentication, presentation]

requires:
  - phase: 199-13
    provides: "Immutable 40-warning first-run ledger and sealed raw-output provenance"
  - phase: 199-15
    provides: "Planning-independent source-tree verifier and fixture schema for authorized Dialyzer slices"
provides:
  - "Exact seven-warning fixture for W21 and W27-W32 across four authorized operator-boundary origins"
  - "Reachable map-shaped fallback actor and Plug.Conn remote-address contracts"
  - "Binary-only presentation helpers and exhaustive redaction-reason presentation"
affects: [199-20, DECOUPLE-07, DECOUPLE-08]

actuals:
  tokens: 2136
  tasks: 2
  commits: 4
plan_head_before: b9255ab53c3f6365d64b325a0e7d3c247cfa9430

tech-stack:
  added: []
  patterns:
    - "Operator boundary helpers retain only input shapes supplied by their typed callers"
    - "Redaction parser reason unions are presented by explicit clauses with no silent catchall"

key-files:
  created:
    - test/fixtures/dialyzer/operator-boundaries.json
  modified:
    - lib/threadline/operator_surface/auth.ex
    - lib/threadline/operator_surface/presentation.ex
    - lib/threadline/plug.ex
    - lib/threadline/policy/redaction_presenter.ex
    - test/threadline/plug_test.exs

key-decisions:
  - "Keep Plug remote-address formatting tuple-only because Plug.Conn.remote_ip is an IPv4 or IPv6 tuple; replace the impossible nil test with IPv6 coverage."
  - "Let an unhandled redaction parser reason raise by function-clause mismatch so every future reason requires explicit operator-facing copy."
  - "Operate directly on the binary produced by secondary_ref_value/1 inside private path, email, and URL truncation helpers."

patterns-established:
  - "Bounded operator remediation removes only analyzer-proven unreachable clauses while preserving exact authentication and presentation outputs."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "W21, W30, and W31 are absent after narrowing fallback actor and remote-address handling to reachable map and tuple inputs."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/auth_test.exs and test/threadline/plug_test.exs"
        status: pass
      - kind: integration
        ref: "bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/operator-boundaries.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "W27-W29 are absent while path, email, URL, empty-string, and populated presentation behavior remains unchanged."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/operator_surface/presentation_test.exs"
        status: pass
      - kind: integration
        ref: "operator-boundaries slice verifier reports zero live warnings"
        status: pass
    human_judgment: false
  - id: D3
    description: "W32 is absent and every current redaction parser reason retains an explicit operator-facing presentation clause."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "test/threadline/policy/redaction_presenter_test.exs and test/threadline/policy/redaction_presenter_catalog_test.exs"
        status: pass
      - kind: integration
        ref: "operator-boundaries fixture contains exactly seven warnings and four authorized origins"
        status: pass
    human_judgment: false

duration: 6 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 18: Operator Boundary Dialyzer Remediation Summary

**Seven sealed authentication, connection, presentation, and redaction warnings now verify cleanly through reachable input contracts and exhaustive reason handling.**

## Performance

- **Duration:** 6 min
- **Started:** 2026-09-11T18:54:56Z
- **Completed:** 2026-09-11T19:01:53Z
- **Tasks:** 2
- **Implementation files modified:** 6

## Accomplishments

- Sealed exactly W21 and W27-W32 from the original forty-warning analysis with exactly four authorized warning origins.
- Removed the unreachable non-map actor fallback while preserving map-scope identity fallback and mismatch telemetry.
- Narrowed Plug remote-address formatting to the IPv4/IPv6 tuple domain and added truthful IPv6 regression coverage.
- Removed impossible nil coalescing from private binary presentation helpers without changing rendered values.
- Removed the unreachable redaction-reason catchall so a newly introduced reason requires an explicit presentation clause.

## Task Commits

Each TDD task was committed as an atomic RED/GREEN pair:

1. **Task 1 RED: add failing operator boundary warning slice** — `d6afd667` (test)
2. **Task 1 GREEN: narrow operator identity inputs** — `1b7846fe` (feat)
3. **Task 2 RED: expose presentation boundary warnings** — `2e144cfb` (test)
4. **Task 2 GREEN: remove unreachable presentation branches** — `7756fe92` (feat)

## TDD Gate Compliance

- **Task 1 RED:** a temporary named Node test wrapped the unchanged source-owned verifier and failed because W21, W30, and W31 survived. `/tmp/threadline-199-18-task1-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed` before production edits.
- **Task 1 GREEN:** the owned auth/plug command passed 44 tests, and the live verifier reported three of forty sealed warnings, two authorized origins, and zero live warnings. The automatic tracer feedback rerun passed with the same result.
- **Task 2 RED:** the same named-test pattern failed because W27-W29 and W32 survived after fixture expansion. `/tmp/threadline-199-18-task2-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** the owned presentation/redaction command passed 61 tests, and the live verifier reported seven of forty sealed warnings, four authorized origins, and zero live warnings.
- **REFACTOR:** no separate refactor commit was needed; both GREEN implementations were already minimal.
- **Commit order:** `test → feat → test → feat`.

## Verification

- Combined focused suite — **PASS**, 105 tests, 0 failures.
- `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/operator-boundaries.json` — **PASS**, `7/40` sealed warnings, four authorized origins, zero live warnings.
- Targeted `mix format --check-formatted` — **PASS**.
- Fixture cardinality and authority — **PASS**, IDs are exactly W21 and W27-W32; all seven dispositions are `fixed`; authority contains exactly the four plan-owned warning origins.
- `.dialyzer_ignore.exs` diff from the plan base — **PASS**, unchanged.
- Repository-wide `mix test` — **DEFERRED OUT OF SCOPE**, 1,519 tests with the same two pre-existing Dialyzer planning-contract failures recorded by Plans 199-16 and 199-17; no new failure appeared.

## Files Created/Modified

- `test/fixtures/dialyzer/operator-boundaries.json` — exact sealed evidence, dispositions, authority, and zero-warning post-analysis digest for all seven warnings.
- `lib/threadline/operator_surface/auth.ex` — removed only the unreachable non-map fallback-actor clause.
- `lib/threadline/plug.ex` — retained only Plug.Conn's tuple-shaped remote-address formatter.
- `test/threadline/plug_test.exs` — replaced the impossible nil remote address case with IPv6 output coverage.
- `lib/threadline/operator_surface/presentation.ex` — path, email, and URL helpers now consume their already-normalized binary directly.
- `lib/threadline/policy/redaction_presenter.ex` — removed the unreachable wildcard reason formatter.

## Decisions Made

- Plug.Conn's typed IPv4/IPv6 tuple union is the complete supported remote-address contract; binary and nil fallbacks were not retained as hidden compatibility behavior.
- The fallback actor helper remains map-only because its sole call site is the `{:ok, scope} when is_map(scope)` authorization branch.
- Redaction reason presentation remains deliberately closed: adding a parser reason must add its exact operator-facing copy instead of falling through to a generic message.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Replaced an impossible nil remote-address test with IPv6 contract coverage**

- **Found during:** Task 1 GREEN implementation
- **Issue:** The existing plug test supplied `remote_ip: nil`, contradicting Plug.Conn's tuple contract and preventing removal of W30 while the task's verification command included the full plug suite.
- **Fix:** Replaced that unsupported-shape test with an IPv6 tuple assertion, complementing the existing IPv4 assertion and covering both retained union members.
- **Files modified:** `test/threadline/plug_test.exs`
- **Verification:** The auth/plug suite passed 44 tests and the live verifier reported zero warnings in both authorized origins.
- **Committed in:** `1b7846fe`

**2. [Rule 3 - Blocking Issue] Used temporary named Node tests for machine-checkable RED evidence**

- **Found during:** Task 1 and Task 2 RED validation
- **Issue:** The source-owned verifier correctly failed but direct CLI output has no test count, so the centralized RED classifier cannot recognize it as an intentional target-test failure.
- **Fix:** Wrapped the unchanged verifier in a temporary named Node test for each RED gate and preserved both classifier records under `/tmp`.
- **Files modified:** No persistent project file.
- **Verification:** Both evidence records returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Committed in:** No persistent source change required.

---

**Total deviations:** 2 auto-fixed blocking issues.
**Impact on plan:** The adjustments made the retained Plug.Conn contract truthful and the TDD evidence machine-checkable without expanding warning-origin authority or changing product semantics.

## Issues Encountered

- The repository-wide suite reproduced only the two failures already recorded by Plans 199-16 and 199-17: one planning-dependency scan finding and the obsolete fourteen-origin Dialyzer cap. Both are outside Plan 199-18 authority.
- Verification used the sealed analyzer toolchain explicitly (`Elixir 1.19.5-otp-27`, `Erlang 27.3.4.15`) because the shell has no selected default.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The stub scan found only domain uses of the term `mask_placeholder`; no placeholder implementation or unwired data path was introduced.

## Threat Flags

None. The changes narrow existing authentication, connection, and presentation clauses without adding an endpoint, file-access pattern, schema boundary, or authorization capability.

## Next Phase Readiness

- Plan 199-20 can aggregate this exact seven-warning fixture with the other disjoint remediation slices.
- Exactly four warning-origin source files changed, all authorized by Plan 199-18, and suppression configuration is unchanged.
- The two inherited full-suite failures remain owned by their existing Phase-199 remediation paths.

## Self-Check: PASSED

- The operator-boundaries fixture and all five modified implementation/test files exist on disk.
- All four task commit hashes resolve in Git.
- Both persisted RED evidence records classify as `RED_EVIDENCE_OK`.
- The live source-owned verifier reports exactly seven sealed warnings, four authorized origins, and zero live warnings.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
