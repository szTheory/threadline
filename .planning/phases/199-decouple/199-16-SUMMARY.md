---
phase: 199-decouple
plan: "16"
subsystem: static-analysis
tags: [dialyzer, bounded-remediation, tdd, query, storage]

requires:
  - phase: 199-13
    provides: "Immutable 40-warning first-run ledger and sealed raw-output provenance"
  - phase: 199-15
    provides: "Planning-independent source-tree verifier and fixture schema for authorized Dialyzer slices"
provides:
  - "Exact ten-warning fixture for W03, W04, and W33-W40 across five authorized query/storage origins"
  - "Concrete remote struct contracts for AuditChange and AuditTransaction query paths"
  - "Validated continuity schema threading and explicit OTP priv-dir result handling"
affects: [199-17, 199-18, 199-19, 199-20, DECOUPLE-07, DECOUPLE-08]

actuals:
  tokens: 2565
  tasks: 2
  commits: 4
plan_head_before: ce42b508a88a58d402de508eda19f51370843c73

tech-stack:
  added: []
  patterns:
    - "Dialyzer-facing public contracts use concrete remote structs when the dependency does not export a t/0 type"
    - "Functions that validate and normalize values thread the validated return into subsequent checks"
    - "OTP APIs with tagged error tuples are matched explicitly instead of treated as boolean fallbacks"

key-files:
  created:
    - test/fixtures/dialyzer/query-storage.json
  modified:
    - lib/threadline/change_diff.ex
    - lib/threadline/continuity.ex
    - lib/threadline/query.ex
    - lib/threadline/query/actor_history_page.ex
    - lib/threadline/storage/local.ex
    - .planning/phases/199-decouple/deferred-items.md
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "Use concrete AuditChange and AuditTransaction struct types in query contracts because the remote modules do not export t/0 types."
  - "Use the schema returned by continuity validation for table and trigger checks, preserving the validator's normalized value."
  - "Treat :code.priv_dir/1 success as a charlist and fall back to priv only for {:error, :bad_name}."

patterns-established:
  - "A remediation slice expands from a proven tracer to disjoint warnings while retaining exact sealed IDs, origins, raw evidence, and zero live authorized residue."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "W03 and W33-W39 are absent from the three authorized query-contract origins after replacing invalid remote type references with concrete structs."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/change_diff_test.exs, test/threadline/query_test.exs, and test/threadline/operator_surface/live/actor_live_test.exs"
        status: pass
      - kind: integration
        ref: "bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/query-storage.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "W04 is absent after the continuity boundary threads the schema returned by validation into readiness checks."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/continuity_brownfield_test.exs"
        status: pass
      - kind: integration
        ref: "query-storage slice verifier reports zero live warnings"
        status: pass
    human_judgment: false
  - id: D3
    description: "W40 is absent after local storage explicitly distinguishes the OTP priv-dir charlist success from the bad-name error tuple."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "test/threadline/storage/local_test.exs"
        status: pass
      - kind: integration
        ref: "query-storage fixture contains exactly ten sealed warnings and five authorized origins"
        status: pass
    human_judgment: false

duration: 13 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 16: Query and Storage Dialyzer Remediation Summary

**Ten sealed query/storage warnings now verify cleanly through the source-owned slice checker, with concrete struct contracts and behavior-preserving continuity/storage fixes.**

## Performance

- **Duration:** 13 min
- **Started:** 2026-09-11T18:10:49Z
- **Completed:** 2026-09-11T18:23:32Z
- **Tasks:** 2
- **Implementation files modified:** 6

## Accomplishments

- Sealed exactly W03, W04, and W33-W40 from the original 40-warning analysis with exactly five authorized origins.
- Replaced invalid remote `t/0` references with concrete `%AuditChange{}` and `%AuditTransaction{}` contracts without changing query runtime behavior.
- Threaded the schema returned by continuity validation into table existence and trigger coverage checks.
- Replaced the ineffective boolean priv-dir fallback with explicit charlist success and `{:error, :bad_name}` handling.
- Verified that all ten fixed warnings are absent from current Dialyzer output without adding or changing suppressions.

## Task Commits

Each TDD task was committed as an atomic RED/GREEN pair:

1. **Task 1 RED: add failing query/storage warning slice** — `9fc9dbc3` (test)
2. **Task 1 GREEN: use concrete query struct contracts** — `280a12e8` (feat)
3. **Task 2 RED: expose continuity and storage warnings** — `a948e83d` (test)
4. **Task 2 GREEN: thread validated schema and handle priv-dir errors** — `ec34c865` (feat)

## TDD Gate Compliance

- **Task 1 RED:** a temporary named ExUnit wrapper around `bin/verify-dialyzer-slice` exited 2 because W03 and W33-W39 survived. `/tmp/threadline-199-16-task1-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed` before production edits.
- **Task 1 GREEN:** the owned 79-test command passed, and the live verifier reported eight of forty sealed warnings, three authorized origins, and zero live warnings. The automatic tracer feedback rerun passed with the same result.
- **Task 2 RED:** the same temporary named wrapper exited 2 because W04 and W40 survived at `lib/threadline/continuity.ex:70` and `lib/threadline/storage/local.ex:68`. `/tmp/threadline-199-16-task2-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** the owned nine-test command passed, and the live verifier reported ten of forty sealed warnings, five authorized origins, and zero live warnings.
- **REFACTOR:** no separate refactor commit was needed; both GREEN changes were already minimal.
- **Commit order:** `test → feat → test → feat`.

## Verification

- `mix test test/threadline/change_diff_test.exs test/threadline/query_test.exs test/threadline/operator_surface/live/actor_live_test.exs --max-failures 1` — **PASS**, 79 tests, 0 failures.
- `mix test test/threadline/continuity_brownfield_test.exs test/threadline/storage/local_test.exs --max-failures 1` — **PASS**, 9 tests, 0 failures.
- `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/query-storage.json` — **PASS**, `10/40` sealed warnings, five authorized origins, zero live warnings.
- Targeted `mix format --check-formatted` — **PASS**.
- Fixture cardinality and authority check — **PASS**, IDs are exactly W03, W04, and W33-W40; origins are exactly the five plan-authorized files; every disposition is `fixed`.
- Current-plan implementation diff — **PASS**, exactly the fixture and five authorized source origins.
- `.dialyzer_ignore.exs` diff from the plan base — **PASS**, empty.
- Repository-wide `mix test` — **DEFERRED OUT OF SCOPE**, 1,519 tests with two failures in pre-existing Dialyzer planning-contract tests; recorded in `deferred-items.md`.

## Files Created/Modified

- `test/fixtures/dialyzer/query-storage.json` — exact sealed evidence, dispositions, authority, and zero-warning post-analysis digest for the ten-warning slice.
- `lib/threadline/change_diff.ex` — concrete AuditChange struct contract.
- `lib/threadline/query.ex` — concrete AuditChange and AuditTransaction contracts across timeline, history, preload, and transaction helpers.
- `lib/threadline/query/actor_history_page.ex` — concrete AuditTransaction entry contract.
- `lib/threadline/continuity.ex` — validated schema return threaded into readiness checks.
- `lib/threadline/storage/local.ex` — explicit OTP priv-dir result matching.

## Decisions Made

- Concrete remote structs are the truthful Dialyzer contract where the remote schema modules do not export `t/0`; no local wrapper types or suppression entries are introduced.
- Continuity readiness uses the validator's returned schema instead of discarding it, keeping validation and downstream lookup on one normalized value.
- The local adapter preserves the existing `priv/threadline_exports` fallback, but only for the documented bad-application-name result rather than all truthy tuples.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Added temporary named ExUnit wrappers for machine-checkable RED evidence**

- **Found during:** Task 1 RED evidence validation
- **Issue:** The source-owned verifier correctly failed, but direct CLI output contains no test count, so the centralized RED classifier reported zero tests discovered.
- **Fix:** Wrapped the unchanged verifier command in a temporary named ExUnit test for each RED gate, validated the expected warning-survival failure, then removed the wrapper before each production edit and commit.
- **Files modified:** No persistent file; the temporary test was never committed.
- **Verification:** Both evidence records returned `RED_EVIDENCE_OK` with reason `target_test_failed`.

**2. [Rule 3 - Blocking Issue] Recorded unrelated full-suite contract failures for their owning plan**

- **Found during:** Overall verification
- **Issue:** The repository-wide suite contains two failures in existing Dialyzer contract tests outside Plan 199-16 authority.
- **Fix:** Preserved the failures without editing unauthorized test files and recorded exact evidence in the phase deferred-item ledger.
- **Files modified:** `.planning/phases/199-decouple/deferred-items.md`
- **Verification:** All Plan 199-16 focused tests and the exact live slice verifier pass.

**3. [Rule 3 - Blocking Issue] Reconciled Phase 199 roadmap progress after the SDK found no writable phase entry**

- **Found during:** Post-summary planning-state synchronization
- **Issue:** `roadmap.update-plan-progress 199` returned `missing_phase_details` although the Phase 199 checklist and progress row exist.
- **Fix:** Marked only Plan 199-16 complete and reconciled the phase row to the SDK-measured 15 summaries across 21 plans; every unfinished row remains unchecked.
- **Files modified:** `.planning/ROADMAP.md`
- **Verification:** Plan 199-16 is checked, the phase row reads `15/21 | In Progress`, and Plans 199-17 through 199-21 plus the deferred Plan 199-14 remain unchecked.

---

**Total deviations:** 3 auto-fixed blocking workflow issues.
**Impact on plan:** Product scope is unchanged; no warning origin outside the five-file authority was edited.

## Issues Encountered

- The repository-wide suite's two failures predate and fall outside this slice: one contract rejects an existing planning-history read, and another retains a 14-origin cap against the current 22-origin sealed analysis.
- Verification used the repository's analyzer toolchain explicitly (`Elixir 1.19.5-otp-27`, `Erlang 27.3.4.15`) because the shell has multiple ASDF installations and no selected default.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The stub scan found only normal empty-string/list guards and documentation prose; no placeholder data path was introduced.

## Threat Flags

None. The changes add no endpoint, authentication path, file-access capability, schema boundary, or new trust surface.

## Next Phase Readiness

- Plans 199-17 through 199-20 can reuse the same source-owned verifier and disjoint fixture pattern.
- Exactly five warning-origin files changed, all authorized by Plan 199-16, and no suppression file changed.
- The two repository-wide contract failures remain visible in the phase deferred ledger for their owning remediation plan.

## Self-Check: PASSED

- The query-storage fixture and all five authorized implementation files exist on disk.
- All four task commit hashes resolve in Git.
- Both persisted RED evidence records classify as `RED_EVIDENCE_OK`.
- The live source-owned verifier reports exactly ten sealed warnings, five authorized origins, and zero live warnings.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
