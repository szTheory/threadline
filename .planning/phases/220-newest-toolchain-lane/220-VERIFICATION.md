---
phase: 220-newest-toolchain-lane
verified: 2026-09-28T22:30:00Z
status: gaps_found
score: 8/12 must-haves verified
covered_files:
  - ".github/workflows/ci.yml"
  - ".planning/phases/220-newest-toolchain-lane/220-01-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-01-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-02-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-02-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-03-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-03-SUMMARY.md"
  - ".planning/phases/220-newest-toolchain-lane/220-04-PLAN.md"
  - ".planning/phases/220-newest-toolchain-lane/220-04-SUMMARY.md"
  - "CONTRIBUTING.md"
  - "README.md"
  - "lib/mix/tasks/threadline.incident.ex"
  - "lib/threadline/critic_trust/ledger_splice.ex"
  - "lib/threadline/operator_surface/live/actor_live.ex"
  - "lib/threadline/operator_surface/live/evidence_live.ex"
  - "lib/threadline/operator_surface/live/export_status_live/components.ex"
  - "mix.exs"
  - "test/support/migration_harness.ex"
  - "test/threadline/ci_workflow_parity_contract_test.exs"
covered_digest: "v2:sha256:46c9ce6f49c16f16ba82aa70a4debdc32d007883e8ec0b08aa7119a41e0b5f5c"
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "SC3: A contract test proves no voting lane uses `continue-on-error` and no lane uses a beta PostgreSQL image"
    status: failed
    reason: "Both contracts pass on today's tree, but neither is fail-closed. I reproduced four spellings that bypass them by running the contract's own regexes: a registry-prefixed beta image (`image: docker.io/library/postgres:19beta1`) is not scanned; `postgres:${{ matrix.pg }}rc1` is read as a bare `${{ matrix.pg }}`; a quoted key (`\"continue-on-error\": true`) is not matched; and a flow-mapped step (`- { name: x, continue-on-error: true }`) is not matched. All four are valid YAML that GitHub honours. So the contract does not prove the property for the next edit, which is what SC3 asks for."
    artifacts:
      - path: "test/threadline/ci_workflow_parity_contract_test.exs"
        issue: "`@postgres_image_ref` (line 678) uses a negative lookbehind that skips every prefixed image and stops at `}}`. The continue-on-error and allowed-failures regexes in `voting_lane_errors/1` (lines 608 and 615) are anchored to a bare key at the start of a line."
    missing:
      - "Match PostgreSQL images on `image:` lines, with an optional registry or namespace prefix. Treat an empty tag, an `@sha256:` digest or any text after `}}` as pg-tag or pg-unresolved (WR-02)"
      - "Make the continue-on-error and allowed-failures regexes accept quoted keys and flow mappings (IN-01)"
      - "Add a mutation control for each of these: `docker.io/library/postgres:19beta1`, `postgres:${{ matrix.pg }}rc1`, bare `postgres`, a quoted `\"continue-on-error\": true` and a flow-mapped step"
  - truth: "D-15: `voting_lane_errors/1` fails closed, so no voting lane can be made non-blocking. `ci-required.needs` must equal every ci.yml job key"
    status: failed
    reason: "`workflow_jobs/1` and `workflow_job/2` only recognise `[a-z][a-z0-9-]+` job ids. A job named `verify_latest:` folds into the job before it, so it never enters the `jobs` set and escapes the needs-coverage check (reproduced, WR-03). A step-level `if: matrix.lane != 'latest'` on Compile, xref or Run tests, or `mix verify.test || true`, leaves the latest lane voting green while it runs nothing. No test pins those steps as unconditional (WR-01)."
    artifacts:
      - path: "test/threadline/ci_workflow_parity_contract_test.exs"
        issue: "Job-header regex at lines 1545 and 1555. No check that the every-lane verify-test steps have no `if:` and run the exact expected command."
    missing:
      - "Widen the job-id pattern to `[A-Za-z_][A-Za-z0-9_-]*` in both `workflow_jobs/1` and `workflow_job/2`, and add an underscore-job needs-coverage control (WR-03)"
      - "Add an every-lane step rule: Compile (warnings as errors), Verify no compile-connected xref cycles and Run tests carry no `if:` and run exactly their commands. Add controls for `if: matrix.lane != 'latest'` and `|| true` (WR-01)"
  - truth: "D-16: `postgres_image_errors/1` scans every PostgreSQL image in every workflow file and docker-compose.yml"
    status: failed
    reason: "Same root cause as the SC3 gap. Prefixed, untagged and digest-pinned images are never scanned, and an expression followed by a suffix resolves to release tags (WR-02, reproduced)."
    artifacts:
      - path: "test/threadline/ci_workflow_parity_contract_test.exs"
        issue: "`@postgres_image_ref` and `postgres_image_refs/1`"
    missing:
      - "Fixed by the same change as the first SC3 missing item"
  - truth: "The docs describe the latest lane as voting through `CI required`, consistent with `.github/rulesets/main.json`"
    status: partial
    reason: "The CONTRIBUTING 'Branch protection (maintainers)' list (lines 883-891) tells maintainers to 'require these checks on `main`', and this phase added `Run test suite (latest)` to it. The paragraph right below it says the only required context is `CI required`, and `bin/verify-branch-protection` enforces exactly that one context. A maintainer who follows the list turns the protection check red (WR-04). The contradiction existed before this phase, and this phase added to it."
    artifacts:
      - path: "CONTRIBUTING.md"
        issue: "Lines 883-891 present the job list as required contexts"
    missing:
      - "Reword the list as the jobs that `CI required` aggregates through `needs:`. Keep the `Run test suite (latest)` string so the doc-contract assertion still holds"
---

# Phase 220: Newest-Toolchain Lane Verification Report

**Phase Goal:** The suite is proven (or honestly not yet proven) on the newest stable Elixir, OTP and PostgreSQL before any adopter hits them.
**Verified:** 2026-09-28
**Status:** gaps_found
**Re-verification:** No. This is the initial verification.

The lane half of the goal is achieved. The newest toolchain is proven green and votes on PR #60. The fail-closed contract half (SC3) is not. The contracts exist and are green, but each can be bypassed by a spelling I reproduced. All four gaps share one root cause and one fix pass: the open review findings WR-01..WR-04 and IN-01, already routed to `/gsd-code-review 220 --fix`.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC1: a dispatch spike run, cited by run ID, runs the suite on exactly pinned Elixir 1.20.x / OTP 29.x / PG 18 under `--warnings-as-errors` | ✓ VERIFIED | `gh run view 36484105399`: `workflow_dispatch` on `spike/220-latest`, headSha `4a32cbf6`, conclusion success, 16/16 jobs success. In the latest job's log: `version-type: strict`, `Installing Erlang/OTP OTP-29.1.1`, `Using Elixir 1.20.4 (built for Erlang/OTP 29)`, `docker pull postgres:18.6`, `Run mix compile --warnings-as-errors`, `No cycles found`, `Result: 2513 passed (9 properties, 2504 tests), 3 excluded` |
| 2 | SC2: on green, `lane: latest` is a voting `verify-test` entry, with roster and parity contract tests updated in the same commit | ✓ VERIFIED | `ci.yml:338` reads `lane: [min, current, latest]`. The latest row pins `1.20.4` / `29.1.1` / `"18.6"` / `ubuntu-24.04`. Commit `4a32cbf6` changes ci.yml and the parity contract test together, and its only non-comment ci.yml changes are the axis and the row. The row has no `if:` and no `continue-on-error`. The PR #60 run (36487483472) shows `Run test suite (latest)` success and `CI required` success |
| 3 | SC3: a contract test proves no voting lane uses `continue-on-error` and no lane uses a beta PostgreSQL image | ✗ FAILED | Both contracts exist and pass on today's tree (63 tests, 0 failures), and the canonical mutation controls work. They are not fail-closed: 4 reproduced bypasses (see Gaps) |
| 4 | D-08: the six Elixir 1.20 warnings are removed without a behaviour change or version-conditional code | ✓ VERIFIED | `ledger_splice.ex:85` uses `binary_part(text, open, …)`. The `require Logger` lines are gone from both files. The review traced each removal to unreachable code. Compile `--warnings-as-errors` passed on the min, current and latest lanes in both runs |
| 5 | D-14: `latest_row_errors/2` checks shape and that each version is strictly newer than current, never literal values, with a control per rule | ✓ VERIFIED | Contract tests pass. The review confirms each mutation control asserts its own error fragment |
| 6 | D-15: `voting_lane_errors/1` fails closed (no lane can be made non-blocking; needs covers every job) | ✗ FAILED | An underscore job id escapes needs coverage (reproduced). A step `if:` or `\|\| true` makes the lane vacuous. A quoted or flow-mapped continue-on-error escapes the check |
| 7 | D-16: `postgres_image_errors/1` scans every PostgreSQL image | ✗ FAILED | `docker.io/library/postgres:19beta1` gives `[]`, and `postgres:${{ matrix.pg }}rc1` resolves to a bare expression (reproduced) |
| 8 | D-17: README, CONTRIBUTING and mix.exs describe latest as **tested on**, not a support floor, with no literal pins | ✓ VERIFIED | README line 102 says "tested on … not a new support floor". CONTRIBUTING line 39 has the matching text |
| 9 | D-18: the MILESTONE-GUIDE closeout gains the re-pin line | ✓ VERIFIED | `.planning/MILESTONE-GUIDE.txt:347` |
| 10 | D-04/D-07: `ci-required`, the ruleset and `bin/verify-branch-protection` are unchanged | ✓ VERIFIED | `git diff fcb22e00 4a32cbf6 --stat -- .github/rulesets bin/` is empty |
| 11 | Landing: PR #60 carries the spike tip by fast-forward, and the PR run is cited with CI required and latest both green | ✓ VERIFIED | The `land/v1.43-217-218` ref on origin is `4a32cbf6`, and PR #60 headRefOid is `4a32cbf6` (OPEN). `merge-base --is-ancestor fcb22e00 4a32cbf6` holds. Run 36487483472 is a `pull_request` run with success on all 16 jobs. The remote `spike/220-latest` no longer exists |
| 12 | The docs consistently describe latest as voting through `CI required` | ✗ FAILED (partial) | CONTRIBUTING lines 883-891 contradict the single required context (WR-04) |

**Score:** 8/12 truths verified (0 present but behavior-unverified)

### Tree-equality gate (orchestrator question)

I re-ran it under `bash -c` with proper word splitting over the 11 paths in `git diff --name-only fcb22e00 4a32cbf6`. Ten paths are byte-equal between `milestone/v1.43` and `4a32cbf6`. `mix.exs` differs only in `@version "0.11.0"` (milestone) against `"0.11.1"` (land). That is a release-please bump that predates this phase. **It does not matter for the goal.** The phase's own `mix.exs` hunk, a support comment, is identical on both. The land branch carrying a newer release version than the milestone branch is the expected shape of the landing model. The earlier zsh check really was vacuous, and the 220-04 SUMMARY's correction is accurate.

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `.github/workflows/ci.yml` | voting latest row | ✓ VERIFIED | Axis and row present; runs on PR #60 |
| `test/threadline/ci_workflow_parity_contract_test.exs` | roster, latest pin-shape, voting-lane and PG-tag contracts | ⚠️ PRESENT, NOT FAIL-CLOSED | `latest_row_errors`, `voting_lane_errors` and `postgres_image_errors` all exist and pass, but the last two have reproduced bypasses |
| `CONTRIBUTING.md` | `Run test suite (latest)` and the tested-on statement | ⚠️ VERIFIED with a warning | Contains both, plus the WR-04 contradiction |
| `README.md` | "not a new support floor" | ✓ VERIFIED | line 102 |
| `.planning/MILESTONE-GUIDE.txt` | re-pin line | ✓ VERIFIED | line 347 |
| `220-SPIKE.md` | run IDs, `## Outcome`, `## Landing` | ✓ VERIFIED | Outcome is GREEN. Runs 36484105399 and 36487483472 are cited, and both match `gh` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| parity contract test | `.github/workflows/ci.yml` | `verify_test_matrix_errors`, `voting_lane_errors` and `postgres_image_errors` read the live workflow | WIRED | Presence is asserted for each file (the scan is not vacuous) |
| `ledger_splice.ex` | `ledger_splice_test.exs` | splice tests | WIRED | Covered by suite runs in CI |
| `220-SPIKE.md` | `ci.yml` via CI required | the landing run | WIRED | Run 36487483472 |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Spike run green on the exact pins | `gh run view 36484105399 --json headSha,conclusion,jobs` plus a log grep | success; 16/16; the pins appear in the log | ✓ PASS |
| PR #60 run green on the landed SHA | `gh run view 36487483472 --json headSha,conclusion,jobs` | headSha `4a32cbf6`, success, 16/16 | ✓ PASS |
| Contract tests green | `mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs` | 63 tests, 0 failures | ✓ PASS |
| Contract fail-closed on non-canonical spellings | `elixir` scratch probe applying the contract's exact regexes | prefixed beta image → `[]`; `${{ matrix.pg }}rc1` → bare expr; underscore job folded; quoted and flow-mapped continue-on-error unmatched | ✗ FAIL |

### Probe Execution

None declared. SKIPPED.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| LANE-01 | 220-01..04 | Dispatch spike on Elixir 1.20.x / OTP 29.x / PG 18, exactly pinned, under `--warnings-as-errors` | ✓ SATISFIED | Run 36484105399 (truth 1). REQUIREMENTS.md still shows `Pending`, and the orchestrator should update it on phase close |

No orphaned requirements: REQUIREMENTS.md maps only LANE-01 to Phase 220.

### Prohibitions (judgment-tier, non-authoritative LLM verdict)

| Prohibition | Verdict |
|-------------|---------|
| No version-conditional D-08 fix | holds (no `Version.match?` or version branching in the diff) |
| No `mix.lock` / `.tool-versions` / min-pin change | holds (neither file is in `fcb22e00..4a32cbf6`; the min row is unchanged) |
| No ruleset, ci-required or `if:` / `allowed-skips` for latest | holds |
| Latest lane gains no example app, Dialyzer or test `--warnings-as-errors` | holds (the only non-comment ci.yml changes are the axis and the row) |
| No voting lane can be made non-blocking; no pre-release PG | holds for today's tree. **Enforcement is incomplete** (gaps above) |
| No push or dispatch outside the named grant | not verifiable from code. SPIKE.md records the orchestrator push under the maintainer grant |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `test/threadline/ci_workflow_parity_contract_test.exs` | 678 | lookbehind regex skips prefixed images | 🛑 Blocker (SC3) | A beta PG image can land green |
| `test/threadline/ci_workflow_parity_contract_test.exs` | 608, 615 | key regex misses quoted keys and flow maps | 🛑 Blocker (SC3) | continue-on-error can land green |
| `test/threadline/ci_workflow_parity_contract_test.exs` | 1545, 1555 | job-id regex excludes `_` | 🛑 Blocker (D-15) | A lane can be left out of CI required |
| `test/threadline/ci_workflow_parity_contract_test.exs` | 446 | D-17 assertion satisfied only by a YAML comment (IN-02) | ℹ️ Info | Pins prose, not behaviour |
| `test/threadline/ci_workflow_parity_contract_test.exs` | ~1658 | stale two-row comment (IN-03) | ℹ️ Info | — |
| `CONTRIBUTING.md` | 883-891 | required-check list contradicts the ruleset (WR-04) | ⚠️ Warning | Misleads maintainers |

There are no TBD, FIXME or XXX markers in the touched files.

### Human Verification Required

None. Every check was automated.

### Gaps Summary

The toolchain half of Phase 220 is done and proven. The spike run 36484105399 ran on exact 1.20.4 / 29.1.1 / 18.6 pins with `version-type: strict` and was green. The voting latest row landed on PR #60 by fast-forward, and PR run 36487483472 is green on 16/16 jobs, including `CI required` and `Run test suite (latest)`.

SC3 is not met. It asks for a contract that *proves* no voting lane uses continue-on-error and no lane uses a beta PostgreSQL image. That is a regression guard, and the plan's D-15/D-16 truths call it fail-closed. I reproduced the review's bypasses with the contract's own regexes, and every bypass is ordinary, valid workflow YAML. They are the open WR-01, WR-02 and WR-03 findings plus IN-01. IN-01 was filed as Info, but it directly defeats SC3's continue-on-error clause, so I treat it as blocking. WR-04 is a doc contradiction the phase made worse, and it belongs in the same fix pass.

The fix is one commit to the parity contract test plus one CONTRIBUTING paragraph, then one more landing push to PR #60. No later phase in the roadmap clearly covers this (Phase 222's fail-closed classifier is a different contract), so nothing is deferred. Route: `/gsd-code-review 220 --fix`, then re-verify.

---

_Verified: 2026-09-28_
_Verifier: Claude (gsd-verifier)_
