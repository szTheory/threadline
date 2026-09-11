---
phase: 199-decouple
plan: "15"
subsystem: static-analysis
tags: [dialyzer, bounded-remediation, tdd, warning-provenance, critic-tooling]

requires:
  - phase: 199-08
    provides: "Planning-independent source-tree test inputs and full optional-app build inputs"
  - phase: 199-13
    provides: "Immutable 40-warning first-run ledger and sealed raw-output provenance"
provides:
  - "Planning-independent executable for verifying one authorized Dialyzer warning slice"
  - "Schema-versioned warning fixture with exact origins, raw lines, dispositions, and bounded post-analysis hash"
  - "Behavior-preserving fixes for critic-tooling warnings W01, W02, and W05"
affects: [199-16, 199-17, 199-18, 199-19, 199-20, DECOUPLE-07, DECOUPLE-08]

actuals:
  tokens: 6363
  tasks: 2
  commits: 4
plan_head_before: 065e7e6d48a53ad5cfcf24e788867f215ce1b596

tech-stack:
  added: []
  patterns:
    - "Each remediation fixture authorizes exact repository-relative origins and compares only their live raw warnings"
    - "Post-analysis hashes cover sorted authorized warning lines so later disjoint slices cannot invalidate prior evidence"
    - "Fixed warnings must disappear; irreducible residue must preserve an exact tuple, rationale, and removal trigger"

key-files:
  created:
    - bin/verify-dialyzer-slice
    - test/threadline/dialyzer_slice_contract_test.exs
    - test/fixtures/dialyzer/critic-tooling.json
  modified:
    - lib/threadline/critic_trust/measure.ex
    - lib/mix/tasks/critic.measure.ex
    - lib/mix/tasks/critic.synth.ex

key-decisions:
  - "Hash only normalized raw warnings inside a fixture's authorized origins; the sealed-run hash remains the immutable whole-run provenance while slice hashes remain stable as other origins are remediated."
  - "Reject malformed raw warning lines and require the fixture authority set to equal its recorded warning-origin set exactly."
  - "Represent unconditional Mix.raise/1 helpers with truthful private no_return() specs rather than changing runtime control flow or weakening caller contracts."

patterns-established:
  - "Bounded Dialyzer remediation: transcribe exact sealed evidence, prove the declared fixed warning survives in RED, apply only authorized source fixes, then seal zero authorized live warnings."

requirements-completed: [DECOUPLE-07, DECOUPLE-08]

coverage:
  - id: D1
    description: "A source-owned verifier validates schema version, exact authority, raw warning provenance, dispositions, and current bounded Dialyzer output without reading the planning tree."
    requirement: DECOUPLE-07
    verification:
      - kind: unit
        ref: "test/threadline/dialyzer_slice_contract_test.exs#synthetic raw output and malformed authority controls"
        status: pass
      - kind: integration
        ref: "bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json"
        status: pass
    human_judgment: false
  - id: D2
    description: "W01, W02, and W05 retain exact sealed provenance and are absent from the three authorized critic-tooling origins without suppression entries."
    requirement: DECOUPLE-08
    verification:
      - kind: integration
        ref: "test/fixtures/dialyzer/critic-tooling.json plus live verify-dialyzer-slice result: 3/40 sealed, 0 live"
        status: pass
      - kind: other
        ref: "git diff --name-only ecc1c0a1 -- lib and .dialyzer_ignore.exs immutability check"
        status: pass
    human_judgment: false
  - id: D3
    description: "Critic measurement determinism and Mix-task operator-facing failure behavior remain unchanged after the narrow fixes."
    requirement: DECOUPLE-08
    verification:
      - kind: unit
        ref: "test/threadline/critic_trust/measure_test.exs and test/threadline/operator_surface/critic_trust_test.exs"
        status: pass
    human_judgment: false

duration: 16 min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 15: Bounded Dialyzer Critic-Tooling Remediation Summary

**A planning-independent slice verifier now certifies exact Dialyzer authority and provenance, with W01, W02, and W05 removed by behavior-preserving critic-tooling fixes.**

## Performance

- **Duration:** 16 min
- **Started:** 2026-09-11T17:47:16Z
- **Completed:** 2026-09-11T18:02:34Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Added an executable, repository-anchored slice verifier with deterministic `--raw-output` support and a live raw-Dialyzer mode.
- Added synthetic positive and negative controls covering duplicate IDs, unauthorized origins, surviving fixes, unrecorded live warnings, raw-evidence drift, and incomplete irreducible residue.
- Removed W05 by explicitly consuming the existing `:rand.seed/2` result without changing seed inputs or generated values.
- Removed W01 and W02 with truthful private `no_return()` contracts for the existing unconditional `Mix.raise/1` helpers.
- Sealed exactly three of the original forty warnings with exactly three authorized origins and zero current live warnings in those origins.

## Task Commits

Each TDD task was committed as an atomic RED/GREEN pair:

1. **Task 1 RED: add failing critic Dialyzer slice contract** — `b72c0714` (test)
2. **Task 1 GREEN: consume critic seed state explicitly** — `9f1b3c72` (feat)
3. **Task 2 RED: expose surviving critic task warnings** — `b05dda2f` (test)
4. **Task 2 GREEN: describe critic task failures as no-return** — `2bb8a438` (feat)

## TDD Gate Compliance

- **Task 1 RED:** `ASDF_ERLANG_VERSION=27.3.4.15 ASDF_ELIXIR_VERSION=1.19.5-otp-27 mix test test/threadline/dialyzer_slice_contract_test.exs:9 --max-failures 1` exited 2. The named assertion failed because W05 survived at `lib/threadline/critic_trust/measure.ex:94`. `/tmp/threadline-199-15-task1-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 1 GREEN:** the owned 19-test verifier/measurement command exited 0, and the live verifier reported `1/40` sealed warnings with zero live warnings. The automatic tracer feedback rerun also exited 0 with the same result.
- **Task 2 RED:** the same named live assertion exited 2 after fixture expansion because W01 and W02 both survived at their exact authorized origins. `/tmp/threadline-199-15-task2-red-evidence.json` returned `RED_EVIDENCE_OK` with reason `target_test_failed`.
- **Task 2 GREEN:** the owned 37-test operator/verifier command exited 0, and the live verifier reported `3/40` sealed warnings, three authorized origins, and zero live warnings.
- **REFACTOR:** no separate refactor commit was needed; both GREEN implementations were already narrow.
- **Commit order:** `test → feat → test → feat`.

## Verification

- `mix test test/threadline/dialyzer_slice_contract_test.exs test/threadline/critic_trust/measure_test.exs --max-failures 1` — **PASS**, 19 tests, 0 failures.
- `mix test test/threadline/operator_surface/critic_trust_test.exs test/threadline/dialyzer_slice_contract_test.exs --max-failures 1` — **PASS**, 37 tests, 0 failures.
- `bin/verify-dialyzer-slice --fixture test/fixtures/dialyzer/critic-tooling.json` — **PASS**, `3/40` sealed warnings, three authorized origins, zero live warnings.
- Targeted `mix format --check-formatted` — **PASS**.
- `git diff --name-only ecc1c0a1 -- lib | sort` — **PASS**, exactly the three authorized critic-tooling origins.
- `.dialyzer_ignore.exs` diff from the plan base — **PASS**, empty.
- Fixture cardinality and provenance — **PASS**, IDs are exactly `W01`, `W02`, and `W05`; sealed count is 40; the zero-warning bounded hash is `e3b0c442…b855`.

## Files Created/Modified

- `bin/verify-dialyzer-slice` — schema validation, safe origin normalization, exact raw-warning parsing, bounded live comparison, and authorized-output hashing.
- `test/threadline/dialyzer_slice_contract_test.exs` — live RED/GREEN assertion plus deterministic positive and negative CLI controls.
- `test/fixtures/dialyzer/critic-tooling.json` — immutable sealed-run provenance and exact W01/W02/W05 evidence/dispositions.
- `lib/threadline/critic_trust/measure.ex` — explicit consumption of the deterministic seed-state return.
- `lib/mix/tasks/critic.measure.ex` — truthful private no-return contract for the existing task error helper.
- `lib/mix/tasks/critic.synth.ex` — truthful private no-return contract for the existing task error helper.

## Decisions Made

- The post-analysis digest is deliberately bounded to sorted live warning lines inside `authorized_origins`. Hashing the whole analyzer transcript would include runtime-duration text and would make completed slices fail whenever a later disjoint slice removes another warning.
- The verifier validates every raw warning line before filtering by authority, but reports and hashes only warnings whose normalized origin belongs to the fixture. This preserves parser integrity without granting edit authority over other origins.
- Exact fixture authority is fail-closed: extra authorized paths, unrecorded warnings, duplicate IDs, raw class/origin drift, and stale irreducible residue all fail verification.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The local shell has multiple ASDF Elixir installs and no selected default, so verification was run with the repository's sealed analyzer versions (`Elixir 1.19.5-otp-27`, `Erlang 27.3.4.15`). The executable itself remains version-independent and receives the active toolchain in normal project use.

## Authentication Gates

None.

## User Setup Required

None - no external service configuration required.

## Known Stubs

None.

## Next Phase Readiness

- Plans 199-16 through 199-20 can reuse the stable fixture schema and executable interface for disjoint warning-origin slices.
- No source warning outside the three critic-tooling origins was edited, and no suppression was added.

## Self-Check: PASSED

- All six implementation artifacts and this summary exist on disk.
- All four task commit hashes resolve in Git.
- Both persisted RED evidence records still classify as `RED_EVIDENCE_OK`.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
