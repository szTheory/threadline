---
phase: 225-suite-baseline-and-partitioned-ci
plan: 03
subsystem: testing
tags: [ci, github-actions, elixir, mix-test, partitioning, flake-detection]

requires:
  - phase: 225-suite-baseline-and-partitioned-ci
    plan: 01
    provides: "225-BASELINE.md's D-03 N=3 confirmation, cited by bin/ci-test-partitions's header"
  - phase: 225-suite-baseline-and-partitioned-ci
    plan: 02
    provides: "the D-12 gate commit's test: baseline (225-02's async telemetry commit) and 225-EVIDENCE.md's SUITE-03 section, extended in place"
provides:
  - "bin/ci-test-partitions: the fail-closed partition runner (--self-test, per-PID wait, per-partition logs, GITHUB_STEP_SUMMARY table), called by CI and mix verify.test_partitioned"
  - "verify-test's Run tests step runs mix verify.test_partitioned on every lane, with a self-test mutation-control step before it and MIX_TEST_PARTITION=1 on the current-lane coverage step"
  - "config/test.exs's per-partition database name (threadline_test#{MIX_TEST_PARTITION})"
  - "test/threadline/ci_topology_contract_test.exs's partition_topology_errors/3 checker with 13 mutation controls"
  - "Flake Detection's re-derived sizing (run 36364688861, new ceilings, repeat count unchanged)"
affects: [225-04]

actuals:
  tokens: 13048
  tasks: 3
  commits: 2
  plan_head_before: 9155b6e102a2f39f0abfe8b87782702361976968
  plan_head_after: 699862217635f5b1765b4ee3e6877abc983587d8

tech-stack:
  added: []
  patterns:
    - "Committed CI entrypoint script with a documented test-only seam and --self-test mode (bin/verify-deps-audit's shape), called by both the CI step and a Mix function alias"
    - "Per-PID `wait \"$pid\" || fail=1` aggregation, never a bare `wait` or `a & b & wait` -- the runtime mutation control this phase adds for it"
    - "Per-partition database name via `System.get_env(\"MIX_TEST_PARTITION\")` interpolation, mirrored into any cluster-wide test resource (CREATE ROLE) that also needs partition-uniqueness"

key-files:
  created:
    - bin/ci-test-partitions
  modified:
    - .github/workflows/ci.yml
    - mix.exs
    - config/test.exs
    - test/threadline/ci_topology_contract_test.exs
    - test/threadline/ci_workflow_parity_contract_test.exs
    - .github/workflows/flake-detection.yml
    - test/threadline/flake_classifier_contract_test.exs
    - test/threadline/health/trigger_findings_non_owner_test.exs
    - CONTRIBUTING.md
    - .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md

key-decisions:
  - "D-07 fixed via option 1 (RESEARCH's recommendation): MIX_TEST_PARTITION=1 env on the current-lane Verify Threadline trigger coverage step, reusing partition 1's already-migrated database at zero added wall-clock cost, rather than an explicit extra create+migrate step."
  - "The one .mix_test_failures write under _build/test that survives the D-06 check is accepted as a documented exception: it is Mix's own post-run bookkeeping file (no CLI flag to redirect it), forcing it read-only crashes the whole ExUnit run (File.Error mid-suite), and this repo's aliases never pass --failed, so the race has no consumer and no partial-write risk."
  - "Flake Detection's repeat count stays 12: re-deriving from run 36364688861 plus the one property test added since its head commit still leaves about 17% headroom under the 55-minute budget at 12 repeats, so only the cited run, raw figures, and the two ceiling constants moved."

requirements-completed: [SUITE-02]

coverage:
  - id: D1
    description: "bin/ci-test-partitions runs N concurrent partitions, each on its own database, with a fail-closed per-PID wait aggregation, proven by --self-test's 8 cases and a runtime bare-wait mutation control"
    requirement: SUITE-02
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test"
        status: pass
      - kind: integration
        ref: "mix verify.test_partitioned (local: 3 partitions, all green, 89s total vs 137.0s unpartitioned median)"
        status: pass
    human_judgment: false
  - id: D2
    description: "verify-test's Run tests step runs mix verify.test_partitioned on every lane with an unconditional self-test step before it, MIX_TEST_PARTITION=1 on the coverage step, and job ids/check names unchanged"
    requirement: SUITE-02
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs (partition_topology_errors/3, 13 mutation controls, 23 tests)"
        status: pass
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs (@every_lane_steps, 49 tests)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Local default stays whole and unpartitioned; the D-07 coverage step fails closed against an unmigrated partition database and passes against a migrated one"
    requirement: SUITE-02
    verification:
      - kind: unit
        ref: "mix test (local, 2588 tests, 0 failures)"
        status: pass
      - kind: integration
        ref: "MIX_TEST_PARTITION=1 mix verify.threadline (exit 0) / MIX_TEST_PARTITION=7 mix verify.threadline (exit 1)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Flake Detection's sizing is re-derived from a freshly cited run with the repeat count re-justified, and the gate lands as one D-12 commit"
    requirement: SUITE-02
    verification:
      - kind: unit
        ref: "test/threadline/flake_classifier_contract_test.exs (Test 6, 3 tests)"
        status: pass
      - kind: unit
        ref: "git log --grep='^ci: run the test suite in partitions' (one commit, 10 files, script mode 100755, no .planning leak)"
        status: pass
    human_judgment: false
  - id: D5
    description: "mix ci.all is green on the gate commit"
    requirement: SUITE-02
    verification:
      - kind: integration
        ref: "mix ci.all (exit 0: verify.format/credo/deps_audit/repo_hygiene, compile, xref, bench_compile, verify.test 2588/0, verify.threadline, verify.example 130/0, dialyzer + dialyzer_slice 17/0, browser 317 passed/1 flaky-retried-pass/26 skipped)"
        status: pass
    human_judgment: false

duration: ~2h
completed: 2026-09-30
status: complete
---

# Phase 225 Plan 03: Fail-closed partitioned CI (SUITE-02) Summary

**`bin/ci-test-partitions` runs the suite as N concurrent `mix test --partitions N` processes, one database each, wired into every `verify-test` lane behind a runtime self-test mutation control, landed as one D-12 gate commit with Flake Detection's budget re-derived from a fresh CI run.**

## Performance

- **Duration:** ~2h
- **Started:** 2026-09-30 (approx)
- **Completed:** 2026-09-30
- **Tasks:** 3
- **Files modified:** 10 (1 created, 9 modified), plus the evidence doc

## Accomplishments
- `bin/ci-test-partitions`: a committed, executable (mode 100755) fail-closed partition runner in `bin/verify-deps-audit`'s shape — compiles once serially, forks N `MIX_TEST_PARTITION=i mix test --partitions N --no-compile --no-deps-check` processes, aggregates with `wait "$pid" || fail=1` per recorded PID (never a bare `wait`), writes per-partition logs and status files, prints an ascending partition/timing/counts table to stdout and `$GITHUB_STEP_SUMMARY`, prints only failing partitions' logs on failure, and kills every partition on INT/TERM. `--self-test` proves all 8 documented cases (all pass, a single failure, two failures printed in order, empty+failing, empty+passing, a killed partition, ascending summary order, and four invalid-N cases) through a documented test-only `MIX_BIN` seam.
- `config/test.exs` interpolates `MIX_TEST_PARTITION` into the database name (D-04); `test/threadline/health/trigger_findings_non_owner_test.exs`'s cluster-wide `CREATE ROLE` now folds the same env var into its role name, closing the one genuine cross-partition collision the shared-resource audit found.
- `.github/workflows/ci.yml`'s `verify-test` job: `Run tests` now runs `mix verify.test_partitioned` on every lane, preceded by an unconditional `Prove the gate goes red (failing partition)` step (`bin/ci-test-partitions --self-test`); the current-lane `Verify Threadline trigger coverage` step sets `MIX_TEST_PARTITION: "1"` (D-07) to reuse partition 1's already-migrated database. No job `id:` changed.
- `test/threadline/ci_topology_contract_test.exs` gained `partition_topology_errors/3` and a 13-control mutation test; `test/threadline/ci_workflow_parity_contract_test.exs`'s `@every_lane_steps` and every literal `mix verify.test` fixture that represented the live step were updated to `mix verify.test_partitioned` and the new self-test step.
- Flake Detection's sizing was re-derived from dispatch run `36364688861` (255.9s cold, 197.4-201.2s repeats), with the 5.1s cost of the property test added since that run's head commit folded in; 12 repeats still fits the 55-minute budget with ~17% headroom, so only the cited run, raw figures and the two ceiling constants changed.
- `CONTRIBUTING.md`: the `verify-test` CI-job-table row, a `ci-required` roster sentence naming the self-test proof, a new "N concurrent partitions" paragraph (with the `MIX_TEST_PARTITION`-in-the-name rule for shared resources), and `mix verify.test_partitioned` added to the local command list.
- `mix ci.all` is green on the gate commit: `verify.test` 2588 tests/0 failures, `verify.threadline`, `verify.example` 130/0, Dialyzer + the live slice 17/0, browser lane 317 passed (1 flaky, retried and passed)/26 skipped.

## Task Commits

1. **Tasks 1-2 (no commit per plan instruction):** working-tree only until Task 3's single atomic commit.
2. **Task 3, the D-12 gate:** `ci: run the test suite in partitions, one database each` — `2dd7a963` (ci) — `bin/ci-test-partitions` (mode 100755), `.github/workflows/ci.yml`, `mix.exs`, `config/test.exs`, `test/threadline/ci_topology_contract_test.exs`, `test/threadline/ci_workflow_parity_contract_test.exs`, `.github/workflows/flake-detection.yml`, `test/threadline/flake_classifier_contract_test.exs`, `test/threadline/health/trigger_findings_non_owner_test.exs`, `CONTRIBUTING.md`.
3. **Evidence:** `docs(225): record the partitioned-suite evidence` — `69986221` (docs) — `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md`.

**Plan metadata:** (pending, this commit)

## Files Created/Modified
- `bin/ci-test-partitions` — the fail-closed partition runner and its `--self-test`
- `.github/workflows/ci.yml` — partitioned `Run tests` step, the self-test step, the D-07 `MIX_TEST_PARTITION` env
- `mix.exs` — `verify.test_partitioned` function alias, `ci.all` untouched
- `config/test.exs` — per-partition database name
- `test/threadline/ci_topology_contract_test.exs` — `partition_topology_errors/3` + mutation controls
- `test/threadline/ci_workflow_parity_contract_test.exs` — `@every_lane_steps` and every live-step literal updated
- `.github/workflows/flake-detection.yml` — re-derived budget comment (run 36364688861)
- `test/threadline/flake_classifier_contract_test.exs` — Test 6 ceilings and doc-consistency run id
- `test/threadline/health/trigger_findings_non_owner_test.exs` — partition-suffixed role name
- `CONTRIBUTING.md` — CI job table, roster sentence, partition rule, local command list
- `.planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md` — SUITE-02 local evidence

## Decisions Made
- D-07 resolved via RESEARCH's recommended option 1 (`MIX_TEST_PARTITION=1` env on the coverage step) rather than an explicit extra create+migrate step — zero added wall-clock cost, reuses a database the test run already migrated.
- The one `.mix_test_failures` write under `_build/test` is accepted as a documented, understood exception to the D-06 "prints nothing" check: Mix exposes no flag to redirect it, forcing it read-only crashes the suite outright (strictly worse), and no alias in this repo ever reads it back via `--failed`.
- Flake Detection's repeat count stays at 12 (re-derivation shows ~17% headroom remains); only the cited run and the two ceiling constants moved.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CONTRIBUTING.md's new partition paragraph broke the community-health doc-vocabulary contract**
- **Found during:** Task 3, `mix ci.all`'s `verify.test` step
- **Issue:** The first draft of the new "CI runs the suite as N concurrent partitions" paragraph in CONTRIBUTING.md included a parenthetical `(SUITE-02)` requirement-ID reference, which `test/threadline/community_health_contract_test.exs` forbids in CONTRIBUTING.md (no phase or decision vocabulary in contributor-facing docs) — the test failed with `1 failure` inside `mix ci.all`'s `verify.test` run.
- **Fix:** Removed the `(SUITE-02)` parenthetical; the paragraph reads the same otherwise.
- **Files modified:** `CONTRIBUTING.md`
- **Verification:** `mix test test/threadline/community_health_contract_test.exs` (5/0), then a full green `mix ci.all` re-run.
- **Committed in:** `2dd7a963` (Task 3 gate commit)

**2. [Rule 3 - Blocking] `.mix_test_failures` under `_build/test` fails the D-06 write check**
- **Found during:** Task 1's D-06 local proof
- **Issue:** A `find _build/test -newer <marker> -type f` after a partitioned run always shows `.mix_test_failures` (Mix's own test-failure-tracking manifest), even though a lone no-op `mix compile` never touches it — three concurrent partitions race to overwrite the same file.
- **Fix:** Investigated and confirmed no CLI flag exists to redirect `:failures_manifest_path`, and confirmed (by testing) that making the file read-only crashes the whole ExUnit run with `File.Error` rather than skipping the write gracefully. Documented the write as an accepted, understood exception in `225-EVIDENCE.md`'s D-06 section rather than forcing a worse workaround — the manifest has no consumer in this repo (no alias passes `--failed`) and the race is last-write-wins with no partial-write risk.
- **Files modified:** none (documentation only, in `225-EVIDENCE.md`)
- **Verification:** Confirmed via a solo `mix compile` control (writes nothing) and a read-only-file experiment (crashes the suite).
- **Committed in:** `69986221` (evidence commit)

---

**Total deviations:** 2 auto-fixed (1 Rule 1 bug fix, 1 Rule 3 blocking issue resolved by documentation rather than a worse code change).
**Impact on plan:** Both were necessary to get a truthful green gate; no scope creep.

## Issues Encountered
- Local Postgres showed only transient, self-caused non-idle connections during measurement windows (the `psql` probe itself); no external contention wait was needed.
- None blocking otherwise.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUITE-02 is complete locally: the partition gate, its runtime and shape mutation controls, and the re-derived Flake Detection budget are all on `HEAD` in one commit, green on `mix ci.all`.
- Plan 04 (the CI "after" figures, ≥2 post-change runs of the partitioned step, Flake Detection dispatch confirmation) needs a maintainer-granted push/PR/dispatch — nothing in this plan routes around that gate.
- No blockers for 225-04.

## Self-Check: PASSED

`bin/ci-test-partitions` found on disk (mode 100755); commits `2dd7a963` and `69986221` found in `git log --oneline --all`.

---
*Phase: 225-suite-baseline-and-partitioned-ci*
*Completed: 2026-09-30*
