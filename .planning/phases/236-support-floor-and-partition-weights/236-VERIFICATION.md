---
phase: 236-support-floor-and-partition-weights
verified: 2026-10-07T19:15:37Z
status: passed
score: 6/6 truths verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/236-support-floor-and-partition-weights/236-01-PLAN.md
  - .planning/phases/236-support-floor-and-partition-weights/236-01-SUMMARY.md
  - .planning/phases/236-support-floor-and-partition-weights/236-02-PLAN.md
  - .planning/phases/236-support-floor-and-partition-weights/236-02-SUMMARY.md
  - .planning/phases/236-support-floor-and-partition-weights/236-REVIEW.md
  - .planning/phases/236-support-floor-and-partition-weights/236-SECURITY.md
  - .planning/phases/236-support-floor-and-partition-weights/236-VALIDATION.md
  - CHANGELOG.md
  - README.md
  - bin/ci-test-partitions
  - guides/upgrade-path.md
  - mix.exs
  - test/partition_weights.txt
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/guides/upgrade_path_contract_test.exs
covered_digest: "v3:sha256:2df02b8e4e70623583722acb56e4ccba331c8448a42273c5787808760d0b4deb"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/6
  gaps_closed:
    - "The PostgreSQL 15 minimum lane and its topology-contract pin are introduced in the same commit."
  gaps_remaining: []
  regressions: []
---

# Phase 236: Support Floor and Partition Weights — Verification Report

**Phase Goal:** An adopter sees one support-policy table that matches what CI actually tests. PostgreSQL 15 is the proven minimum, and the partitioned suite weights every test file after this milestone's churn.
**Verified:** 2026-10-07T19:15:37Z
**Status:** passed
**Re-verification:** Yes — after same-commit gap closure

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The `verify-test` minimum lane is PostgreSQL 15, its topology-contract pin is in the same commit, and the topology contract rejects drift. | ✓ VERIFIED | `git show 5895d39d` proves the commit modifies both `.github/workflows/ci.yml` and `test/threadline/ci_topology_contract_test.exs`. It adds the contract pointer inside the `min` row; `minimum_postgres_errors/1` requires that pointer and exact `pg: "15"`. Its test removes the pointer and mutates the lane to 14 and 16, requiring each mutation to fail. |
| 2 | PostgreSQL 15 is the proven supported floor and the Unreleased breaking-change notice tells PostgreSQL 14 adopters to upgrade. | ✓ VERIFIED | `mix.exs` retains the `~> 1.15` Elixir requirement and calls PG15 the minimum; the CI `min` lane uses PG15. `guides/upgrade-path.md`, README, and the Unreleased breaking section agree. `236-VALIDATION.md` records `SHOW server_version_num = 150018`, a 265-file partitioned run with 3,051 tests and no failures, and the aggregate gate. |
| 3 | One support-policy table states the Elixir, OTP, and PostgreSQL floor and CI lanes, with current/latest identified as tested-on evidence; its contract detects source and table drift. | ✓ VERIFIED | `guides/upgrade-path.md` has one “Toolchain support policy” table with `min`, `current`, and `latest` rows. The contract reads the guide and compares its complete version tokens with `mix.exs`, `.tool-versions`, and `ci.yml`; it also checks README and Unreleased breaking claims. |
| 4 | Every discovered test file has one measured, sorted weight, an omitted real path fails with its name, and runner fallback and exactly-once assignment remain intact. | ✓ VERIFIED | An independent path-set comparison found 265 discovered test files and 265 weight rows, with no differences or duplicates. `ci_topology_contract_test.exs` rejects malformed, duplicate, unsorted, missing, and stale rows; its omission mutation names a real path. `bin/ci-test-partitions` retains median fallback and `verify_assignment`; validation records its self-test and the partitioned run. |
| 5 | The PostgreSQL 15 partitioned suite and `mix ci.all` pass with the support and inventory contracts included. | ✓ VERIFIED | `236-VALIDATION.md` records PostgreSQL 15.18 (`150018`), the 265-file / 3,051-test partitioned pass, and final `mix ci.all` exit 0. The supplied `/private/tmp/threadline-phase236-ci-all-green.log` contains the root result (3,051 tests, 0 failures), example result (132, 0 failures), Dialyzer success, and browser result (317 passed, 26 skipped). One browser case failed on its first attempt and passed on retry; the run reports it as flaky. |
| 6 | A green partition run cannot stand in for measured-inventory completeness unless the inventory contract passes. | ✓ VERIFIED | The inventory contract is itself a discovered, weighted test file and is executed by the partitioned suite. It compares the live file inventory with committed measurements and includes a real-path omission mutation. The current 265/265 inventory comparison is complete. |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | PG15 minimum full-suite lane and CI topology | ✓ VERIFIED | `verify-test` min row is `pg: "15"`; full partitioned test step remains enabled. |
| `test/threadline/ci_topology_contract_test.exs` | PG15 pin, topology, and weight-inventory contracts | ✓ VERIFIED | Substantive assertions, adjacent-major and pointer-removal mutations, missing-weight mutation, fallback and assignment checks. |
| `guides/upgrade-path.md` | One source-aligned support-policy table | ✓ VERIFIED | One clearly headed policy table; values match current Mix, tool-version, and CI sources. |
| `test/threadline/guides/upgrade_path_contract_test.exs` | Source-derived guide and adopter-claim contract | ✓ VERIFIED | Reads the guide/source files and README/changelog claims; checks missing, stale, and mutated values. |
| `test/partition_weights.txt` | Measured weights for the full discovered test inventory | ✓ VERIFIED | 265 sorted unique paths match the 265-file live inventory. |
| `bin/ci-test-partitions` | Weighted partition writer and runner invariants | ✓ VERIFIED | Weight writer and runtime reader are substantive; median fallback and exactly-once assignment remain. |
| `README.md`, `CHANGELOG.md`, `mix.exs`, `.tool-versions` | Aligned adopter summary, breaking action, and source values | ✓ VERIFIED | Current PG15 claim and PG14 action agree with the exact CI/source values. |
| Phase validation/review/security records | Gate evidence and review records | ✓ VERIFIED | Validation records PostgreSQL 15.18 and passing gates; review covers 10 files with zero findings; security record has no open threats. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | `test/threadline/ci_topology_contract_test.exs` | Same-commit pointer in min row; parsed and mutation-tested | WIRED | Commit `5895d39d` changes both; test requires the pointer and exact PG15 token. |
| `guides/upgrade-path.md` | `mix.exs`, `.tool-versions`, `.github/workflows/ci.yml` | Source-derived row comparison | WIRED | Guide contract reads all sources and rejects source/table drift. |
| `README.md` | `guides/upgrade-path.md` | Support-summary link | WIRED | Current support bullet links to the policy section; guide contract checks the link. |
| `CHANGELOG.md` | `test/threadline/guides/upgrade_path_contract_test.exs` | Unreleased breaking-action assertion | WIRED | Contract checks PG15 floor and PG14 upgrade instruction. |
| `test/threadline/ci_topology_contract_test.exs` | `test/partition_weights.txt` | Exact path-set comparison | WIRED | Test compares discovered test paths against committed weight rows. |
| `bin/ci-test-partitions` | `test/partition_weights.txt` | Regeneration and runtime assignment | WIRED | Writer and runner name the committed weight file; fallback and assignment self-test remain. |
| `.github/workflows/ci.yml` | `236-VALIDATION.md` | PG15 execution evidence | WIRED (evidence) | A recorded verification relationship, not a runtime source reference; validation cites the exact PG15 server check and commands. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Support-policy table | Elixir, OTP, PostgreSQL lane cells | `mix.exs`, `.tool-versions`, and `ci.yml`, read by the guide contract | Yes | FLOWING |
| Weight inventory | Test paths and measured milliseconds | Filesystem inventory and generated measurements | Yes | FLOWING |
| PostgreSQL floor proof | Server version and test results | PostgreSQL 15.18 server plus test and CI gates | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Evidence | Result | Status |
|---|---|---|---|
| Exact PG15 lane, same-commit contract pointer, and adjacent-major mutation controls | `5895d39d` diff and `236-VALIDATION.md` focused topology/parity run (74 tests, 0 failures) | Pointer removal and PG14/16 mutations are rejected | PASS |
| Weight completeness and omission mutation | Current inventory comparison; validation's focused contract and partition run | 265 paths match; omission error names the missing real path; 3,051 tests pass | PASS |
| PostgreSQL 15 aggregate gate | Saved `/private/tmp/threadline-phase236-ci-all-green.log` and validation record | Root, example, Dialyzer, and browser gates completed; browser retry passed | PASS |

### Probe Execution

No phase-declared or conventional probe scripts were found; not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| FLOOR-01 | 236-01, 236-02 | PostgreSQL 15 minimum, breaking-change notice, and full-suite proof | SATISFIED | Exact CI minimum and topology contract; same-commit linkage in `5895d39d`; PG15.18 partitioned and aggregate evidence. |
| FLOOR-02 | 236-01, 236-02 | One adopter support-policy table aligned with Mix and CI | SATISFIED | Single guide table and contract comparing Mix, `.tool-versions`, and CI values. |
| CI-01 | 236-02 | Regenerated weights and permanent missing-file check | SATISFIED | Live inventory and committed weights match at 265 files; omission mutation is checked; partitioned suite passes. |

No other requirements are mapped to Phase 236; there are no orphaned phase requirements.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---:|---|---|
| `test/threadline/ci_topology_contract_test.exs` | FLOOR-01, CI-01 | Yes | 0 | No | Value and mutation behavior | PASS |
| `test/threadline/guides/upgrade_path_contract_test.exs` | FLOOR-02, FLOOR-01 | Yes | 0 | No | Source-derived value and mutation behavior | PASS |

Disabled requirement tests: 0. Circular expected-value generation: 0. The tests use repository source files and deliberate input mutations.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|

No unresolved debt markers or implementation stubs were found in the phase's changed implementation files. “Placeholder” matches are historical prose or temporary-file templates, not unfinished behavior.

### Advisory (New Scope, Unevidenced)

None. Re-verification found no new-scope concern requiring an advisory.

### Human Verification Required

None. This infrastructure and documentation phase has automated contract, inventory, and PostgreSQL 15 gate evidence; it adds no visual or user-flow behavior.

### Gaps Summary

No unresolved gaps remain. The previous same-commit blocker is closed: commit `5895d39d` changes the PG15 minimum-row pointer and the topology contract together, and the test requires the pointer while checking the exact version and adjacent-major mutations. The support table, source-derived contracts, complete measured inventory, and PostgreSQL 15 test gates are present and connected.

---

_Verified: 2026-10-07T19:15:37Z_  
_Verifier: the agent (gsd-verifier)_
