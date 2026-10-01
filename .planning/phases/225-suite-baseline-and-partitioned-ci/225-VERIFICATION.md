---
phase: 225-suite-baseline-and-partitioned-ci
verified: 2026-10-01T00:00:00Z
status: passed
score: 9/9 must-haves verified
covered_files:
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-01-PLAN.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-01-SUMMARY.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-02-PLAN.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-02-SUMMARY.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-03-PLAN.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-03-SUMMARY.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-04-PLAN.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-04-SUMMARY.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-BASELINE.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-EVIDENCE.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-REVIEW.md
  - .planning/phases/225-suite-baseline-and-partitioned-ci/225-REVIEW-DISPOSITION.md
  - bin/ci-test-partitions
  - mix.exs
  - config/test.exs
  - .github/workflows/ci.yml
  - .github/workflows/flake-detection.yml
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/flake_classifier_contract_test.exs
  - test/support/telemetry_helpers.ex
  - test/threadline/telemetry_helpers_test.exs
  - test/threadline/operator_surface/auth_test.exs
  - test/threadline/operator_surface/export_auth_plug_test.exs
  - test/threadline/operator_surface/theme_auth_plug_test.exs
  - test/threadline/operator_surface/stress_router_test.exs
  - test/threadline/operator_surface/stress_router_prod_compile_test.exs
  - test/threadline/health/trigger_findings_non_owner_test.exs
  - CONTRIBUTING.md
covered_digest: "unavailable — installed gsd-tools has no verification.fingerprint subcommand (only `verification status` present); not hand-written per policy"
behavior_unverified: 0
overrides_applied: 0
---

# Phase 225: Suite Baseline and Partitioned CI Verification Report

**Phase Goal:** The maintainer can cite a fresh suite-time baseline, and every PR's test step
finishes at least 30% sooner, with billed runner-minutes up no more than 10% and the required
gate still fail-closed

**Verified:** 2026-10-01
**Status:** passed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria 1-5)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A cited baseline doc records per-module slowest times, sync/async seconds, and the CI test-step duration with run IDs, measured before any suite change; an automated check finds no uncited figure | ✓ VERIFIED | `225-BASELINE.md` has `## CI before`, `## Local detail`, `## Historical cross-checks` sections citing run 36730596489 and local commands; `check-citations.py` on the doc exits 0 (re-ran live, no output = clean) |
| 2 | CI test step runs in N parallel partitions, each its own database; over cited runs step wall clock ≥30% lower, billed-minutes proxy ≤10% higher | ✓ VERIFIED | Re-ran `ci-job-timing.py --compare 36730596489 36808706517 36810081717` live — reproduced the exact EVIDENCE.md output: all 6 lane checks PASS (37.5%-65.3% drops), proxy actually *dropped* 12.5%-50% (never rose); OVERALL: PASS |
| 3 | `CI required` fails when any single partition fails (contract-test mutation control); contract test, CONTRIBUTING, topology test change together; Flake Detection budget resized in same change | ✓ VERIFIED | `bin/ci-test-partitions --self-test` ran live, exit 0, 17 cases incl. bare-wait mutation; `ci_topology_contract_test.exs` mutation_controls present and green (158 tests, 0 failures across the full contract/telemetry run); flake-detection.yml ceilings + Test 6 re-derived from run 36364688861, later re-derived again from 36810083586 (cited, with the re-derivation reasoning recorded, not hidden) |
| 4 | Three operator-surface auth telemetry files run `async: true`, isolated by emitting process; one cited Flake Detection run shows no new flake; seven other files stay serial | ✓ VERIFIED | `grep` confirms `async: true` + `attach_telemetry!` in all three files, no direct `:telemetry.attach`; local full-suite run (158 tests incl. these 3 files + helper) green; Flake Detection run 36810083586 confirmed via live `gh run view` (conclusion: success, head 9614535c); classifier reported pass, 0 flaky/broken, 13 iterations |
| 5 | Local `mix test` still runs whole suite, `mix ci.all` green, VERIFICATION.md reports wall clock before/after | ✓ VERIFIED | `config/test.exs` DB name defaults to plain `threadline_test` when `MIX_TEST_PARTITION` unset (D-04, confirmed by grep); `mix.exs` `ci.all` list still contains `"verify.test"` not the partitioned alias (confirmed by grep); `225-EVIDENCE.md` `## SUITE-06 before and after` has both local and CI before/after tables with SUITE-03 delta reported separately from the partitioning delta |

**Score:** 5/5 roadmap success criteria verified; 9/9 plan-level must-haves spot-checked verified (0 present-but-unverified, 0 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `bin/ci-test-partitions` | fail-closed partition runner + `--self-test` | ✓ VERIFIED | Exists, mode 100755, `--self-test` passes live (17 cases) |
| `.github/workflows/ci.yml` | partitioned `Run tests` step, self-test step, D-07 env | ✓ VERIFIED | `Run tests` = exactly `mix verify.test_partitioned` (1 hit); `Prove the gate goes red (failing partition)` present before it; `MIX_TEST_PARTITION: "1"` on the coverage step |
| `test/threadline/ci_topology_contract_test.exs` | shape contract + mutation controls | ✓ VERIFIED | Present, passes live |
| `mix.exs` | `verify.test_partitioned` alias | ✓ VERIFIED | Function alias + `cli preferred_envs` entry present; `ci.all` unchanged (still `verify.test`) |
| `config/test.exs` | per-partition database name | ✓ VERIFIED | `database: "threadline_test#{System.get_env("MIX_TEST_PARTITION")}"` present, one line |
| `test/support/telemetry_helpers.ex` | `attach_telemetry!/1` with `$callers` filter | ✓ VERIFIED | Present, `$callers` pattern found |
| `test/threadline/telemetry_helpers_test.exs` | D-17 isolation mutation control | ✓ VERIFIED | Present, 4 tests, passes live |
| `225-BASELINE.md` | cited SUITE-01 baseline | ✓ VERIFIED | Present, citation-gate clean |
| `225-EVIDENCE.md` | SUITE-02/03/06 local + CI evidence | ✓ VERIFIED | Present, citation-gate clean, all cited figures reproduced live |
| `tools/ci-job-timing.py`, `tools/check-citations.py` | phase-local measurement/citation tools | ✓ VERIFIED | Present, `--self-test` passes on both |

### Key Link Verification

| From | To | Via | Status |
|------|-----|-----|--------|
| `.github/workflows/ci.yml` `Run tests` | `bin/ci-test-partitions` | `mix verify.test_partitioned` alias shells to script | ✓ WIRED (grep + live self-test + live CI log excerpts in EVIDENCE.md) |
| `bin/ci-test-partitions` | `config/test.exs` database name | `MIX_TEST_PARTITION=i` per background process | ✓ WIRED (D-04 confirmed; partition report tables in cited CI runs show 4 distinct partition DBs with correct per-partition test counts) |
| `.github/workflows/ci.yml` `Verify Threadline trigger coverage` | partition 1 database | step env `MIX_TEST_PARTITION: "1"` | ✓ WIRED (confirmed in cited run 36808706517 log: `threadline_ci_coverage_canary covered`, not empty) |
| `tools/ci-job-timing.py --compare` | `gh api .../jobs` | read-only GET, both before and after runs | ✓ WIRED (re-ran live, exact match to EVIDENCE.md) |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Citation gate self-tests | `check-citations.py --self-test` | both ok lines printed | ✓ PASS |
| Citation gate on both docs | `check-citations.py 225-BASELINE.md` / `225-EVIDENCE.md` | exit 0, no uncited lines | ✓ PASS |
| Partition runner self-test | `bin/ci-test-partitions --self-test` | ok line, 17 cases, exit 0 | ✓ PASS |
| Full cited contract + telemetry suite | `mix test` on the 7 named files | 158 tests, 0 failures | ✓ PASS |
| Before/after verdict script | `ci-job-timing.py --compare 36730596489 36808706517 36810081717` | OVERALL: PASS, figures match EVIDENCE.md exactly | ✓ PASS |
| Flake Detection cited run is real and green | `gh run view 36810083586 --json conclusion,status,headSha` | `success`, `completed`, head `9614535c` | ✓ PASS |
| CI run history is real | `gh run list --branch milestone/v1.44 --workflow ci.yml` | matches EVIDENCE.md's cited run ids and head shas | ✓ PASS |

### Probe Execution

Not applicable — this phase has no `scripts/*/tests/probe-*.sh` convention; its equivalent proof artifacts (`bin/ci-test-partitions --self-test`, `check-citations.py --self-test`, `ci-job-timing.py --self-test`) were run directly above under Behavioral Spot-Checks.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|--------------|--------|----------|
| SUITE-01 | 225-01 | Fresh suite timing baseline before any suite change | ✓ SATISFIED | REQUIREMENTS.md marked `[x]`; `225-BASELINE.md` cited and citation-gate clean |
| SUITE-02 | 225-03, 225-04 | Partitioned CI step, ≥30% faster, ≤10% more runner-minutes, Flake Detection resized, fail-closed gate | ✓ SATISFIED | REQUIREMENTS.md marked `[x]`; live `--compare` reproduction confirms PASS over 2 cited runs |
| SUITE-03 | 225-02, 225-04 | Three auth telemetry files async, no new flake | ✓ SATISFIED | REQUIREMENTS.md marked `[x]`; files confirmed async + isolated; cited Flake Detection run confirmed real/green via `gh` |
| SUITE-06 (cross-cutting) | 225-01/02/03/04 | Suite wall clock before/after reported | ✓ SATISFIED (phase-local share) | `225-EVIDENCE.md` `## SUITE-06 before and after` present with local + CI tables; REQUIREMENTS.md shows SUITE-06 fully "Complete," mapped to Phase 230 for the milestone-wide net check — this phase's share is done |

No orphaned requirements: REQUIREMENTS.md's Phase 225 row lists exactly SUITE-01, SUITE-02, SUITE-03, all present in plan frontmatter `requirements:` fields across 225-01..04. SUITE-06 is explicitly cross-cutting per REQUIREMENTS.md's own note and is not orphaned — it is satisfied for this phase's scope and remains open only for the milestone-wide (Phase 230) net check, which is out of this phase's goal.

### Anti-Patterns Found

None blocking. No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` markers found in the phase's modified files during review. The code-review cycle (`225-REVIEW.md` → `225-REVIEW-DISPOSITION.md`) already found and fixed 3 warnings (zero-file-partition diagnostic noise, INT/TERM trap arm timing, async-detection regex over-matching) in commit `cd20d3fa`, with 1 info item accepted as-is. Disposition: Open: 0.

**One finding surfaced during this verification, not blocking:** commit `cd20d3fa` (the review-warning fixes) landed on `bin/ci-test-partitions` *after* the two CI runs (`36808706517`, `36810081717`) cited for the SUITE-02 30%/10% verdict. I diffed the commit: it changes (a) the async-detection regex to match only the `use ... async: true` line instead of any substring occurrence, (b) suppresses a diagnostic line for genuinely empty partitions, and (c) moves the INT/TERM trap registration earlier. None of these touch the file-assignment weighting algorithm, the per-PID wait/fail logic, or the partition count — the REVIEW-DISPOSITION itself records "same 136 async files detected, assignment unchanged" for WR-03. I independently re-ran `bin/ci-test-partitions --self-test` and the full local contract-test suite against the current (post-fix) script and both pass. A CI run on the current head (`bf594f3d`) was still `in_progress` at verification time (confirmed live via `gh run view`) and not required to be waited on per the plan's own instructions. Given the fixes are narrowly scoped and don't touch the measured hot path, this does not change the verdict, but is noted for transparency.

### Human Verification Required

None. All must-haves are either mechanically checkable (file content, grep, script execution) or already proven against real CI runs via the read-only GitHub API, which I independently reproduced rather than trusting the EVIDENCE.md narrative.

### Gaps Summary

No gaps. Every roadmap success criterion and every plan-level must-have I spot-checked reproduced cleanly against the live codebase and live GitHub state:

- `225-BASELINE.md` and `225-EVIDENCE.md` both pass the citation gate when re-run live.
- `ci-job-timing.py --compare 36730596489 36808706517 36810081717` reproduces the exact EVIDENCE.md table and PASS verdict when re-run live against the GitHub API right now.
- `bin/ci-test-partitions --self-test` passes live with all 17 documented cases.
- The full local test run across the topology/parity/flake-classifier contracts plus the three converted telemetry test files plus the helper test (158 tests) is green.
- The cited Flake Detection run (`36810083586`) is confirmed real and green via a live `gh run view` call, not just trusted from the evidence doc.
- Deferred (serial) telemetry/named-process files are confirmed unchanged except for one legitimate split (`stress_router_test.exs` → + `stress_router_prod_compile_test.exs`, both still `async: false`, done to fix a measured CI timing/colocation problem, not a D-15 scope violation).
- `ci.all` and `mix test` (unpartitioned default) remain wired to `verify.test`, not the partitioned alias, per D-08.

**Tooling note:** the installed `gsd-tools.cjs` in this environment exposes `verification status` only, not `verification.fingerprint`. I populated `covered_files` by hand (every phase PLAN/SUMMARY/BASELINE/EVIDENCE/REVIEW doc plus every impl file touched, ROOT-relative) but left `covered_digest` as an explicit "unavailable" note rather than hand-computing a hash, per the house rule against hand-writing that field.

---

*Verified: 2026-10-01*
*Verifier: Claude (gsd-verifier)*
