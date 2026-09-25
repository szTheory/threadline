---
phase: 199-decouple
plan: "17"
subsystem: static-analysis
tags: [dialyzer, bounded-remediation, tdd, export, integrations, investigation]

requires:
  - phase: 199-13
    provides: "Immutable 40-warning first-run ledger and sealed raw-output provenance"
  - phase: 199-15
    provides: "Planning-independent source-tree verifier and fixture schema for authorized Dialyzer slices"
provides:
  - "Exact fifteen-warning fixture for W06-W20 across five authorized export, Sigra, and investigation origins"
  - "Concrete binary-list serialization contracts and explicit export temporary-file cleanup handling"
  - "Reachable Sigra identity clauses and concrete investigation struct contracts"
affects: [199-20, DECOUPLE-07, DECOUPLE-08]

actuals:
  tokens: 4280
  tasks: 2
  commits: 4
plan_head_before: f6938b991368c8a3ae315cc28680a366fb1bd176

tech-stack:
  added: []
  patterns:
    - "NimbleCSV output is normalized to binary chunks at the internal serialization boundary before public binary conversion or file writes"
    - "Cleanup helpers inspect every File.close/1 and File.rm/1 result while preserving the primary export result"
    - "Dialyzer-facing contracts use concrete remote structs when Ecto schema modules do not export t/0"

key-files:
  created:
    - test/fixtures/dialyzer/export-investigation.json
  modified:
    - lib/threadline/export.ex
    - lib/threadline/export/orchestrator.ex
    - lib/threadline/integrations/sigra.ex
    - lib/threadline/investigation/incident_bundle.ex
    - lib/threadline/investigation/linked_change.ex
    - .planning/STATE.md
    - .planning/ROADMAP.md

key-decisions:
  - "Normalize CSV and NDJSON rows to binary chunks so the internal list contracts remain concrete without widening public APIs to streams."
  - "Log close and removal failures without replacing the established export success, transaction error, or rescued exception."
  - "Use concrete ActorRef, AuditChange, AuditTransaction, and AuditAction struct types because those providers do not export t/0."
  - "Remove only scalar_id/1's unreachable non-map fallback after confirming every in-module caller is map-guarded."

patterns-established:
  - "A bounded remediation slice retains exact sealed warning provenance while implementation contracts are narrowed to the values the source actually returns."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "W06-W07 are absent after export serializers normalize NimbleCSV and NDJSON output to concrete binary chunks while preserving exact bytes."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/export_test.exs"
        status: pass
      - kind: integration
        ref: "bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/export-investigation.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "W08-W10 are absent after export lifecycle cleanup explicitly handles close and removal results without masking primary outcomes."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "test/threadline/export/orchestrator_test.exs"
        status: pass
      - kind: integration
        ref: "export-investigation slice verifier reports zero live warnings"
        status: pass
    human_judgment: false
  - id: D3
    description: "W11-W20 are absent after Sigra and investigation contracts use reachable clauses and concrete source-tree struct types."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/integrations/sigra_test.exs and test/threadline/investigation_test.exs"
        status: pass
      - kind: integration
        ref: "export-investigation fixture contains exactly fifteen warnings and five authorized origins"
        status: pass
    human_judgment: false

duration: 15 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 17: Export and Investigation Dialyzer Remediation Summary

**Fifteen sealed export, Sigra, and investigation warnings now verify cleanly through exact byte-shape contracts, explicit cleanup handling, and concrete source-tree struct types.**

## Performance

- **Duration:** 15 min
- **Started:** 2026-09-11T18:29:10Z
- **Completed:** 2026-09-11T18:44:16Z
- **Tasks:** 2
- **Implementation files modified:** 6

## Accomplishments

- Sealed exactly W06-W20 from the original 40-warning analysis with exactly five authorized origins.
- Normalized CSV and NDJSON serialization to concrete binary chunks without changing exported bytes.
- Made temporary-file close and removal results explicit while preserving success, error, and rescue precedence.
- Replaced invalid remote `t/0` references with concrete ActorRef and audit struct contracts, and removed only the unreachable Sigra scalar-id fallback.
- Verified all fifteen fixed warnings are absent from current Dialyzer output without adding or changing suppressions.

## Task Commits

Each TDD task was committed as an atomic RED/GREEN pair:

1. **Task 1 RED: add failing export warning slice** — `77d6f0ca` (test)
2. **Task 1 GREEN: make export cleanup results explicit** — `e401faae` (feat)
3. **Task 2 RED: expose Sigra and investigation warnings** — `b8b5522e` (test)
4. **Task 2 GREEN: align integration and investigation contracts** — `b1637c3c` (feat)

## TDD Gate Compliance

- **Task 1 RED:** a temporary named Node test wrapped the unchanged source-owned verifier and failed because W06-W10 survived. `/tmp/threadline-199-17-task1-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed` before production edits.
- **Task 1 GREEN:** the owned 32-test command passed, and the live verifier reported five of forty sealed warnings, two authorized origins, and zero live warnings. The automatic tracer feedback rerun passed with the same result.
- **Task 2 RED:** the same temporary named-test pattern failed because W11-W20 survived after the fixture expanded. `/tmp/threadline-199-17-task2-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** the owned 37-test command passed, and the live verifier reported fifteen of forty sealed warnings, five authorized origins, and zero live warnings.
- **REFACTOR:** no separate refactor commit was needed; both GREEN changes were already minimal.
- **Commit order:** `test → feat → test → feat`.

## Verification

- `mix test test/threadline/export_test.exs test/threadline/export/orchestrator_test.exs --max-failures 1` — **PASS**, 32 tests, 0 failures.
- `mix test test/threadline/integrations/sigra_test.exs test/threadline/investigation_test.exs --max-failures 1` — **PASS**, 37 tests, 0 failures.
- `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/export-investigation.json` — **PASS**, `15/40` sealed warnings, five authorized origins, zero live warnings.
- Targeted `mix format --check-formatted` — **PASS**.
- Fixture cardinality and authority check — **PASS**, IDs are exactly W06-W20; origins are exactly the five plan-authorized files; every disposition is `fixed`.
- Current-plan implementation diff — **PASS**, exactly the fixture and five authorized source origins.
- `.dialyzer_ignore.exs` diff from the plan base — **PASS**, empty.
- Repository-wide `mix test` — **DEFERRED OUT OF SCOPE**, 1,519 tests with the same two pre-existing Dialyzer planning-contract failures already recorded by Plan 199-16 in `deferred-items.md`.

## Files Created/Modified

- `test/fixtures/dialyzer/export-investigation.json` — exact sealed evidence, dispositions, authority, and zero-warning post-analysis digest for W06-W20.
- `lib/threadline/export.ex` — concrete binary-list serialization at CSV and NDJSON boundaries.
- `lib/threadline/export/orchestrator.ex` — explicit close/removal handling with primary-result precedence preserved.
- `lib/threadline/integrations/sigra.ex` — concrete ActorRef contracts and removal of the unreachable scalar-id fallback.
- `lib/threadline/investigation/incident_bundle.ex` — concrete AuditTransaction and AuditAction field contracts.
- `lib/threadline/investigation/linked_change.ex` — concrete AuditChange, AuditTransaction, and AuditAction field contracts.

## Decisions Made

- Export serializers expose the concrete `[binary()]` shape they already materialize; no public contract is widened to accept a stream.
- Cleanup errors are logged and consumed after explicit matching so they cannot silently replace the primary export result.
- Concrete remote structs are the truthful Dialyzer contract where the provider schema modules do not export `t/0`; no wrapper types or suppression entries are introduced.
- The non-map `scalar_id/1` fallback is unreachable because every direct caller is either guarded with `is_map/1` or receives a value from a guarded wrapper.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking Issue] Added temporary named Node tests for machine-checkable RED evidence**

- **Found during:** Task 1 and Task 2 RED evidence validation
- **Issue:** The source-owned verifier correctly failed, but direct CLI output has no test count for the centralized RED classifier.
- **Fix:** Wrapped the unchanged verifier command in a temporary named Node test for each RED gate and validated the expected warning-survival failure before production edits.
- **Files modified:** No persistent file; the temporary tests were never committed.
- **Verification:** Both evidence records returned `RED_EVIDENCE_OK` with reason `target_test_failed`.

**2. [Rule 3 - Blocking Issue] Reconciled Phase 199 roadmap progress after the SDK found no writable phase entry**

- **Found during:** Post-summary planning-state synchronization
- **Issue:** `roadmap.update-plan-progress 199` returned `missing_phase_details` although the Phase 199 checklist and progress row exist.
- **Fix:** Marked only Plan 199-17 complete and reconciled the phase row to the SDK-measured 16 summaries across 21 plans; every unfinished row remains unchecked.
- **Files modified:** `.planning/ROADMAP.md`
- **Verification:** Plan 199-17 is checked, the phase row reads `16/21 | In Progress`, and Plans 199-18 through 199-21 plus deferred Plan 199-14 remain unchecked.

---

**Total deviations:** 2 auto-fixed blocking workflow issues.
**Impact on plan:** Product scope is unchanged; no warning origin outside the five-file authority was edited.

## Issues Encountered

- The repository-wide suite retains the same two failures documented by Plan 199-16: one contract rejects an existing planning-history read, and another retains a 14-origin cap against the current 22-origin sealed analysis. Neither failing test is in Plan 199-17 authority.
- Verification used the repository's analyzer toolchain explicitly (`Elixir 1.19.5-otp-27`, `Erlang 27.3.4.15`) because the shell has multiple ASDF installations and no selected default.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None. The stub scan found only normal empty-string guards; no placeholder data path was introduced.

## Threat Flags

None. The changes add no endpoint, authentication path, file-access capability, schema boundary, or new trust surface.

## Next Phase Readiness

- Plan 199-20 can aggregate this exact source-backed slice with the other disjoint warning-remediation fixtures.
- Exactly five warning-origin files changed, all authorized by Plan 199-17, and no suppression file changed.
- The two repository-wide contract failures remain visible in the phase deferred ledger for their owning remediation plan.

## Self-Check: PASSED

- The export-investigation fixture and all five authorized implementation files exist on disk.
- All four task commit hashes resolve in Git.
- Both persisted RED evidence records classify as `RED_EVIDENCE_OK`.
- The live source-owned verifier reports exactly fifteen sealed warnings, five authorized origins, and zero live warnings.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
