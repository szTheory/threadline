---
phase: 236-support-floor-and-partition-weights
verified: 2026-10-08T01:36:57Z
status: passed
score: 6/6 truths verified
covered_files:
  - .github/workflows/ci.yml
  - .planning/phases/236-support-floor-and-partition-weights/236-01-PLAN.md
  - .planning/phases/236-support-floor-and-partition-weights/236-01-SUMMARY.md
  - .planning/phases/236-support-floor-and-partition-weights/236-02-PLAN.md
  - .planning/phases/236-support-floor-and-partition-weights/236-02-SUMMARY.md
  - .tool-versions
  - CHANGELOG.md
  - README.md
  - bin/ci-test-partitions
  - guides/upgrade-path.md
  - mix.exs
  - test/partition_weights.txt
  - test/threadline/ci_topology_contract_test.exs
  - test/threadline/ci_workflow_parity_contract_test.exs
  - test/threadline/guides/upgrade_path_contract_test.exs
covered_digest: "v3:sha256:e76d0acf0b022236ed783953a72465cc91d8cbb9d736c0b785b7eebdfc40be1b"
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: passed
  previous_score: 6/6
  gaps_closed: []
  gaps_remaining: []
  regressions: []
---

# Phase 236: Support Floor and Partition Weights — Verification Report

**Phase Goal:** An adopter sees one support-policy table that matches what CI actually tests. PostgreSQL 15 is the proven minimum, and the partitioned suite weights every test file after this milestone's churn.
**Verified:** 2026-10-08T01:36:57Z
**Status:** passed
**Re-verification:** Yes — refreshing stale fingerprint and current inventory evidence

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|---|---|---|
| 1 | The `verify-test` minimum lane is PostgreSQL 15 exactly, its topology-contract pin is coupled in the same commit, and drift is rejected. | ✓ VERIFIED | `.github/workflows/ci.yml` pins the `min` row to `"15"` and links the contract. Commit `5895d39d600f916917f780efc64d0569aeb41631` changes both workflow and `ci_topology_contract_test.exs`. The contract tests exact value, missing pointer, and mutations to 14 and 16; fresh focused run passed. |
| 2 | PostgreSQL 15 is the adopter support floor, with the Unreleased notice telling PostgreSQL 14 adopters to upgrade first. | ✓ VERIFIED | `mix.exs`, CI, README current-support summary, guide, and Unreleased breaking section agree. `upgrade_path_contract_test.exs` checks these claims and stale/deleted-value mutations. |
| 3 | One policy table gives exact Elixir, OTP, and PostgreSQL min/current/latest values, and labels current/latest as tested-on evidence only. | ✓ VERIFIED | `guides/upgrade-path.md` has one toolchain policy table. Its source-derived contract reads `mix.exs`, `.tool-versions`, and the `verify-test` matrix and compares full version tokens and lane meanings. The workspace removed only the unrelated `nodejs` pin from `.tool-versions`; its Elixir and Erlang values still match. |
| 4 | Every discovered test file has exactly one sorted measured weight, and omitting a real path fails with that path named. | ✓ VERIFIED | The live inventory and `test/partition_weights.txt` each contain 266 test paths; the focused contract compares the exact path sets and exercises omitted, malformed, duplicate, unsorted, and stale-row mutations. |
| 5 | The partition runner retains median fallback for missing weights and exactly-once file assignment. | ✓ VERIFIED | `bin/ci-test-partitions` still applies the median fallback, verifies duplicate/out-of-range/missing assignments, and refuses to execute an incomplete assignment. The topology contract retains the runtime self-test for these behaviors. |
| 6 | The weighted partition suite and aggregate gate pass on PostgreSQL 15. | ✓ VERIFIED | Current-tree canonical run: `DB_HOST=127.0.0.1 DB_PORT=55433 MIX_ENV=test mix verify.test_partitioned` exited 0 on PostgreSQL 15.18 (`server_version_num=150018`), with 266 files and 3,058 tests, 0 failures (partition counts 841, 871, 842, 504). The Phase 236 validation record also captures a green `mix ci.all` on PostgreSQL 15.18: root 3,051 tests + 32 properties, example 132 tests, Dialyzer passed, and browser 317 passed / 26 skipped (one flaky case passed on retry). |

**Score:** 6/6 truths verified (0 present, behavior-unverified)

### Plan Prohibitions

| Must-not | Status | Evidence |
|---|---|---|
| No current adopter-facing claim says PostgreSQL 14 remains supported. | ✓ VERIFIED | README and current Unreleased/guide claims say PostgreSQL 15; their contract includes stale-claim mutation controls. Historical release notes retain their historical PostgreSQL 14 statements as planned. |
| Current/latest table rows are not presented as guaranteed support promises. | ✓ VERIFIED | Both rows say “tested-on only; not a support promise”; the guide contract checks those labels and exact lane values. |
| A passing partition run is not presented as proof of measured-weight completeness unless the inventory contract passes too. | ✓ VERIFIED | The current report cites the passing completeness contract and matching 266-path inventory alongside the partition run. |

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.github/workflows/ci.yml` | PG15 minimum full-suite lane and contract pointer | ✓ VERIFIED | `verify-test` min row is `pg: "15"`; full partitioned test step remains enabled. |
| `test/threadline/ci_topology_contract_test.exs` | Exact floor, topology, inventory, and mutation contracts | ✓ VERIFIED | Substantive ExUnit assertions; current focused run passes. |
| `guides/upgrade-path.md` | One support-policy table | ✓ VERIFIED | Single table with min/current/latest rows and tested-on labels. |
| `test/threadline/guides/upgrade_path_contract_test.exs` | Source-derived guide, README, and changelog contract | ✓ VERIFIED | Reads repository sources and uses stale-value/deletion mutations. |
| `test/partition_weights.txt` | Measurements for all discovered tests | ✓ VERIFIED | 266 sorted paths match the live `find` inventory exactly. |
| `bin/ci-test-partitions` | Weight writer and safe runtime assignment | ✓ VERIFIED | Writer and runner are substantive; fallback and exactly-once checks remain. |
| `README.md`, `CHANGELOG.md`, `mix.exs`, `.tool-versions` | Aligned support statement and source values | ✓ VERIFIED | Current claims align; changed `.tool-versions` entries remain consistent. |
| `236-VALIDATION.md` | PostgreSQL 15 integration and aggregate evidence | ✓ VERIFIED | Recorded PG15.18 and green `mix ci.all`; current-tree partition run independently refreshed above. |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | `test/threadline/ci_topology_contract_test.exs` | Contract pointer in min row and exact-value mutation test | WIRED | Same commit `5895d39d` changes both; test requires the pointer and exact PG15 value. |
| `guides/upgrade-path.md` | Mix, `.tool-versions`, and CI matrix | Source-derived policy comparison | WIRED | Contract reads and compares each current source value against the table. |
| `README.md` | `guides/upgrade-path.md` | Policy-table link | WIRED | README links to the guide section; the contract asserts the link. |
| `CHANGELOG.md` | `test/threadline/guides/upgrade_path_contract_test.exs` | Unreleased breaking-action assertions | WIRED | Test reads the changelog and checks floor plus PostgreSQL 14 upgrade action. |
| `test/threadline/ci_topology_contract_test.exs` | `test/partition_weights.txt` | Exact inventory/path-set comparison | WIRED | Current contract passes for all 266 paths. |
| `bin/ci-test-partitions` | `test/partition_weights.txt` | Weight regeneration and runtime assignment | WIRED | Writer and runner use the committed file; current partitions assigned 266 files once. |
| CI minimum | `236-VALIDATION.md` | Recorded PG15 execution proof | WIRED (evidence) | This is a verification-record relationship, not a runtime source reference; PostgreSQL version and gate results are recorded. |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| Support-policy table | Elixir/OTP/PG cells | Mix, `.tool-versions`, and CI matrix read by the guide contract | Yes | FLOWING |
| Weight inventory | Test paths and measured milliseconds | Live filesystem inventory and measured file contents | Yes | FLOWING |
| PostgreSQL floor proof | Server version and test results | PG15.18 query plus current partition and recorded aggregate gates | Yes | FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| Floor pin, same-commit pointer, source/table agreement, inventory and mutation contracts | `mix verify.test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/guides/upgrade_path_contract_test.exs` | 77 tests, 0 failures | PASS |
| Full weighted test assignment and execution on supported floor | `DB_HOST=127.0.0.1 DB_PORT=55433 MIX_ENV=test mix verify.test_partitioned` | PG15.18; 266 files, 3,058 tests, 0 failures | PASS |
| Aggregate root/example/Dialyzer/browser gate on supported floor | Recorded `mix ci.all` in `236-VALIDATION.md` | Exit 0 on PG15.18; root/example/Dialyzer passed; browser retry recovered one flaky case | PASS |

The first sandboxed local partition attempt could not write the npm cache or `.git/worktrees`; the canonical elevated run above passed. This limitation did not remain in the final gate result.

### Probe Execution

No phase-declared or conventional probe scripts were found; not applicable.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| FLOOR-01 | 236-01, 236-02 | PostgreSQL 15 minimum, breaking notice, and full-suite proof | SATISFIED | Exact CI minimum and same-commit contract; current PG15.18 partitioned suite and recorded PG15 aggregate gate. |
| FLOOR-02 | 236-01, 236-02 | One adopter table aligned with Mix and CI | SATISFIED | Single table and fresh source-derived contract run. |
| CI-01 | 236-02 | Regenerated weights and permanent missing-file check | SATISFIED | Current exact 266-path inventory match, omission mutation, and successful 266-file partition run. |

No other requirements are mapped to Phase 236; there are no orphaned phase requirements.

### Test Quality Audit

| Test File | Linked Requirement | Active | Skipped | Circular | Assertion Level | Verdict |
|---|---|---:|---:|---|---|---|
| `test/threadline/ci_topology_contract_test.exs` | FLOOR-01, CI-01 | Yes | 0 disabled | No | Value and mutation behavior | PASS |
| `test/threadline/ci_workflow_parity_contract_test.exs` | FLOOR-01 | Yes | 0 disabled | No | Value and topology parity | PASS |
| `test/threadline/guides/upgrade_path_contract_test.exs` | FLOOR-02, FLOOR-01 | Yes | 0 disabled | No | Source-derived value and mutation behavior | PASS |

No disabled requirement tests or circular expected-value generation were found. The contracts read repository sources and deliberately mutate fixture strings.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---:|---|---|---|

No unresolved debt markers or implementation stubs were found in the changed implementation files. Matches for “placeholder” are historical prose or test fixture descriptions, not unfinished behavior.

### Decision Coverage

No `CONTEXT.md` exists for Phase 236; nothing to check.

### Human Verification Required

N/A — infrastructure/foundation phase with no user-facing elements. All acceptance criteria are verifiable programmatically.

### Gaps Summary

No unresolved gaps remain. The support-floor contract, source-derived adopter table, measured inventory, safe partition assignment, and PostgreSQL 15 proof are present and connected. The refreshed fingerprint includes the current `.tool-versions` and 266-file inventory.

---

_Verified: 2026-10-08T01:36:57Z_
_Verifier: the agent (gsd-verifier)_
