---
phase: 218-ci-economy-remove-waste
plan: 01
subsystem: ci-release
status: complete
tags: [ci, release, release-please, econ-03, contract-test]
requires: []
provides:
  - "PAT-absence guard on bootstrap-release-pr-ci's CI dispatch"
  - "bootstrap_guard_errors/1 contract helper with four mutation controls"
affects: [.github/workflows/release.yml, test/threadline/release_control_plane_contract_test.exs]
tech-stack:
  added: []
  patterns:
    - "job-level env boolean (`secrets.X != ''`) to gate a step on secret presence without exporting the secret"
    - "contract helper returning failed {bool, message} pairs, proven non-vacuous by String.replace mutation controls"
key-files:
  created: []
  modified:
    - .github/workflows/release.yml
    - test/threadline/release_control_plane_contract_test.exs
decisions:
  - "ECON-03 (D-06a): bootstrap-release-pr-ci dispatches ci.yml only when RELEASE_PLEASE_TOKEN is absent, gated by job-level env RELEASE_PAT_CONFIGURED; wiring (needs, always(), permissions) unchanged"
  - "The four mutation controls are unrolled (one explicit control per guard property) rather than looped, so each control message is individually grep-visible"
metrics:
  duration: 4min
  completed: 2026-09-27
actuals:
  tokens: 1600
  tasks: 2
  commits: 4
plan_head_before: 5b67b61b315c4a55b8ab85a5c02514ea4d77f279
plan_head_after: 733f031b1d683d30ea3795b5cf8d5b49a7b4abd1
---

# Phase 218 Plan 01: Release PR CI Single-Run Guard Summary

`bootstrap-release-pr-ci` now dispatches `ci.yml` only when `RELEASE_PLEASE_TOKEN` is absent. The job reads a boolean-only job-level env (`RELEASE_PAT_CONFIGURED: ${{ secrets.RELEASE_PLEASE_TOKEN != '' }}`) and never queries workflow runs. A contract test pins the guard, and four mutation controls prove the test goes red when any part of the guard breaks.

## What changed

- **`.github/workflows/release.yml`, job `bootstrap-release-pr-ci`**
  - New job-level `env:` exports only the result of the boolean comparison, never the token value (T-218-01).
  - New first step, `Record whether the PAT already fans out CI`, emits a `::notice::` with `configured=true|false`.
  - The `Dispatch CI on release PR branch` step now has `if: env.RELEASE_PAT_CONFIGURED != 'true'`. Its `env: GH_TOKEN` and `run:` lines are unchanged.
  - The job comment was extended with the rationale: the double-run evidence pair run 36256339043 / run 36256344029, why the no-PAT dispatch must stay, the expired-PAT behaviour, and the rule that the job reads configuration only.
  - `needs:`, the job `if: always() ...` line and `permissions:` are byte-identical. The diff has no `-` lines for them.
- **`test/threadline/release_control_plane_contract_test.exs`**
  - New private helper `bootstrap_guard_errors/1` checks four properties:
    - `actions: write` is kept;
    - the boolean-only env line is present;
    - the step guard is present;
    - no `gh run list`, `gh run view` or `actions/runs` appears. The message for this one: "a run query makes the bootstrap decision depend on timing, which ECON-03 forbids".
  - The existing pin-sync/bootstrap test now asserts `bootstrap_guard_errors(bootstrap) == []`.
  - New test "the bootstrap guard contract is not vacuous" runs four controls: step guard dropped, comparison flipped, env from the raw secret, and run query added. Each control asserts first that it changed the input, then that the helper result is non-empty.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 (tracer) | 2c2ce72b | ci(218-01): dispatch release-PR CI only when no PAT fans it out |
| 2 RED | 024e7044 | test(218-01): add failing mutation controls for the release PAT guard |
| 2 GREEN | e0595786 | test(218-01): prove the release PAT guard contract goes red |
| 2 REFACTOR | 733f031b | refactor(218-01): unroll the release PAT guard mutation controls |

## Verification

- `actionlint -shellcheck=` exits 0 with no diagnostics. This confirms that the `secrets` context is accepted in `jobs.<id>.env` (RESEARCH assumption A2).
- `mix test test/threadline/release_control_plane_contract_test.exs`: 8 tests, 0 failures.
- `mix verify.format` exits 0. `mix verify.credo` found no issues.
- Full default `mix test`: 9 properties, 2381 tests, 0 failures, 2 excluded (the standard exclusion `pgbouncer_topology`).
- Task 1 tracer gate: the `<verify>` step was re-run end-to-end after the commit and was green, so the plan expanded to Task 2.
- Acceptance counts:
  - `bootstrap_guard_errors`: 7 occurrences (at least 3 required).
  - `control did not change the input`: 1 before Task 2, 5 after, an increase of exactly 4.
  - The Task 1 commit touches exactly the two planned files. The Task 2 commits touch only the test file.

## TDD Gate Compliance

RED commit 024e7044 came before GREEN commit e0595786, and the REFACTOR commit 733f031b followed it.

The RED run used `mix test test/threadline/release_control_plane_contract_test.exs`, which exited non-zero:

```
  1) test the bootstrap guard contract is not vacuous (Threadline.ReleaseControlPlaneContractTest)
     the run query added control must turn the bootstrap guard contract red
8 tests, 1 failure
```

This was the intended failure. The first three controls passed, and the run-query control stayed green because the helper did not yet have the never-queries-runs invariant. GREEN added that invariant.

`check tdd-red-evidence` returned `RED_EVIDENCE_OK` (`target_test_failed`). That validator only parses TAP or Surefire output, so the record fed to it was a faithful TAP transcription of the real ExUnit result: 8 tests, 7 ok, the target test not ok.

## Deviations from Plan

1. **[Rule 3 - Blocking] Task 2 split into RED, GREEN and REFACTOR commits instead of one commit.** The plan named one `test(218-01): prove ...` commit, but the task is `tdd="true"` and the dispatch hazard 9 requires a real RED commit first. The GREEN commit uses the planned subject.
2. **[Rule 1 - Bug] The mutation controls were unrolled in a REFACTOR commit.** The first GREEN version looped over the four controls, so the literal "control did not change the input" appeared only once more (1 to 2), and the acceptance criterion requires exactly +4. The controls are now four explicit blocks, and the count goes from 1 to 5.
3. **Grep portability note (no code change).** The Task 1 acceptance command `grep -c "RELEASE_PAT_CONFIGURED: \${{ secrets.RELEASE_PLEASE_TOKEN != '' }}"` prints 0 with macOS BSD grep, because `{{` is parsed as an interval expression. `grep -cF` with the same string prints 1, and the contract-test regex also matches the line.

## Flagged / unverifiable here

- "Exactly one CI run per release PR head" cannot be observed until the next release cycle. The contract test proves the guard's shape. Plan 218-08 records the one-run claim as [inference] from the run 36256339043 / run 36256344029 pair.
- The prohibition "a release PR must never end up with zero CI runs" is protected structurally: the no-PAT path always dispatches, and `always()`, `needs:` and `actions: write` are unchanged and asserted. It is not observed live.

## Known Stubs

None.

## Hand-offs

None. No GitHub writes were needed.

## Self-Check: PASSED

- FOUND: .github/workflows/release.yml (contains RELEASE_PAT_CONFIGURED)
- FOUND: test/threadline/release_control_plane_contract_test.exs (contains bootstrap_guard_errors)
- FOUND commits: 2c2ce72b, 024e7044, e0595786, 733f031b
