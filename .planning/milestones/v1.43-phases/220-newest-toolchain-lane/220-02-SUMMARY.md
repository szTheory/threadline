---
phase: 220-newest-toolchain-lane
plan: 02
subsystem: infra
tags: [ci, verify-test, latest-lane, contract-tests, postgres, fail-closed]

requires:
  - phase: 220-01
    provides: "Zero Elixir 1.20 own-code warnings; re-verified pins 1.20.4 / 29.1.1 / 18.6"
provides:
  - "Voting `lane: latest` row in verify-test (Elixir 1.20.4 / OTP 29.1.1 / PG 18.6, explicit pins)"
  - "Three-row roster parity plus latest_row_errors/2 (shape and strictly-newer checks, no literal latest pins)"
  - "voting_lane_errors/1: no continue-on-error anywhere, no allowed-failures, ci-required needs = every ci.yml job"
  - "postgres_image_errors/1: release-tag allowlist over every workflow plus docker-compose.yml"
  - "Tested-on (not a support floor) docs in README, CONTRIBUTING and mix.exs; D-18 re-pin checklist line"
affects: [220-03, 222, ci.yml verify-test, CI required]

actuals:
  tokens: 38000
  tasks: 3
  commits: 2
plan_head_before: bd2b20ada39def37c4606ddd6930e559e0e1e8fc
plan_head_after: 5a037db252f9bd498413cb1f949894211fa1eaa9

tech-stack:
  added: []
  patterns:
    - "Pin-shape contract: regex shape + strictly-newer ordering against .tool-versions, never literal values, so a milestone re-pin touches only ci.yml"
    - "Controls derive live values from the parsed include rows, so they survive a re-pin"

key-files:
  created:
    - .planning/phases/220-newest-toolchain-lane/COVERAGE.md
  modified:
    - .github/workflows/ci.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
    - CONTRIBUTING.md
    - README.md
    - mix.exs
    - .planning/MILESTONE-GUIDE.txt

key-decisions:
  - "Pinned elixir 1.20.4, otp 29.1.1, pg 18.6 (220-01 pins, re-checked the same day)"
  - "The newer-than checks fail closed when the current value is missing or cannot be parsed. A shape-invalid latest value skips its newer-than check, so the test reports the shape error and never crashes"
  - "The postgres image scan treats a file with no jobs: section (docker-compose.yml) as one unit, labelled job=(file)"

requirements-completed: [LANE-01]

coverage:
  - id: D1
    description: "Latest row, three-row roster and D-14 pin-shape controls green against the live ci.yml"
    requirement: "LANE-01"
    verification:
      - kind: other
        ref: "actionlint -shellcheck= .github/workflows/ci.yml"
        status: pass
      - kind: unit
        ref: "mix test test/threadline/ci_workflow_parity_contract_test.exs"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-15 voting-lane and D-16 PostgreSQL-tag contracts fail closed, one control per bypass shape plus positive controls"
    requirement: "LANE-01"
    verification:
      - kind: unit
        ref: "mix test test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_topology_contract_test.exs (62 tests, 0 failures)"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-17 docs asserted by a parity test; the full gate stack is green before either commit"
    requirement: "LANE-01"
    verification:
      - kind: integration
        ref: "mix ci.all (CIALL_EXIT=0 on the permitted re-run)"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-09-28
status: complete
---

# Phase 220 Plan 02: Voting latest lane and fail-closed lane contracts Summary

**verify-test gains a third, voting `lane: latest` row (Elixir 1.20.4 / OTP 29.1.1 / PostgreSQL 18.6). Contract tests pin its shape and require it to be strictly newer than the current lane. They also fail closed on any `continue-on-error`, any `allowed-failures`, a gap in `ci-required` needs, or a pre-release PostgreSQL image in any workflow or in docker-compose. The docs describe the lane as "tested on", not as a support floor.**

## Commits

| Commit | SHA | Files |
|--------|-----|-------|
| A (code, D-10; plan 03 cherry-picks this) | `77ff2392a873a1aa7f1840b9492d983d86bf2be6` | `.github/workflows/ci.yml`, `CONTRIBUTING.md`, `README.md`, `mix.exs`, `test/threadline/ci_workflow_parity_contract_test.exs` |
| B (planning docs) | `5a037db252f9bd498413cb1f949894211fa1eaa9` | `.planning/MILESTONE-GUIDE.txt`, `.planning/phases/220-newest-toolchain-lane/COVERAGE.md` |

`git diff --quiet 77ff2392^ 5a037db2 -- .tool-versions mix.lock .github/rulesets/main.json bin/verify-branch-protection` exits 0. `ci-required` and the min and current rows are unchanged.

## Gate results (verbatim summary lines)

1. `actionlint -shellcheck= .github/workflows/ci.yml`: no output, exit 0.
2. Four CI contract files (parity, topology, action-runtime, browser-full-projects): `108 tests, 0 failures`.
3. `mix format --check-formatted`: clean after one `mix format` of the test file. `mix verify.credo`: `4315 mods/funs, found no issues.` `mix verify.test`: `9 properties, 2507 tests, 0 failures, 3 excluded`. `bin/verify-repo-hygiene`: `verify-repo-hygiene: 4077 tracked text file(s) clean; 8 allowlist entries used, 0 inert`.
4. `mix ci.all`:
   - **Run 1: red** at `verify.example` with `FATAL 53300 (too_many_connections)`. At that point 78 of the shared local Postgres's 100 connections were idle `rindle_test` connections from another project, so the failure was environmental. Its root suite had already passed: `9 properties, 2507 tests, 0 failures, 3 excluded`.
   - **Run 2 (the one permitted re-run): `CIALL_EXIT=0`.**
     - Root suite: `9 properties, 2507 tests, 0 failures, 3 excluded`.
     - Example suites: `130 tests, 0 failures` and `17 tests, 0 failures, 16 excluded`.
     - Dialyzer: `Total errors: 0, Skipped: 0, Unnecessary Skips: 0` / `done (passed successfully)`.
     - Playwright (CI=true lane): `318 passed (4.2m)`, `26 skipped`, 0 failed. This is the expected 318/0/26.

## Accomplishments

### Task 1 (tracer): the latest row, the roster and the pin-shape contract
- **The row.** ci.yml's axis is now `lane: [min, current, latest]`. The latest row sets `elixir`, `otp`, `pg` and `runner` only; it has no `version-file`, no `if:` and no `allowed-skips`.
- **The roster.** `verify_test_matrix_errors/3` requires exactly three rows, keyed `["current", "latest", "min"]`. The extra-row control is renamed `"a fourth matrix row"`.
- **The pin-shape contract.** `current_toolchain/2` and `latest_row_errors/2` hold the D-14 rules. Their controls cover:
  - an added `version-file`
  - a bare OTP major (`otp: "29"`)
  - an rc Elixir (`1.20.0-rc.1`)
  - a pg that is not newer (`16`)
  - a 22.04 runner
  - a raised `.tool-versions` (1.99.0 / 99.0), which trips both the Elixir and the OTP newer-than messages
- **Tracer gate.** Auto mode was off and the gate is end-of-phase, with an automated-only verify. It re-ran green before expansion: the parity file passed at `39 tests, 0 failures`.

### Task 2 (TDD): the fail-closed contracts
The tests were written first against stubs. **RED:** the parity file reported `41 tests, 2 failures`, the two vacuity guards. **GREEN:** after implementation, the parity and topology files reported `62 tests, 0 failures`.
- **`voting_lane_errors/1`.** Its controls cover:
  - job-level `continue-on-error` on verify-test
  - step-level `continue-on-error` on `Run tests`
  - the `${{ matrix.lane == 'latest' }}` form
  - `allowed-failures` in ci-required
  - dropping `verify-test` from ci-required's needs
  - a positive control: the word `continue-on-error` inside a comment stays green
- **`postgres_image_errors/1` / `postgres_image_tags/1` / `image_sources/0`.**
  - Controls: `19beta1` in the latest row, `postgres:18rc1` in browser-full.yml, `postgres:devel` in release.yml, and `${{ matrix.pg_tag }}` (unresolvable).
  - Positive control: an added `postgres://` connection URL leaves the tag list unchanged.
  - Non-vacuity: each of the five files has an image, and verify-test's matrix expression resolves to exactly the three row pg values.

### Task 3: docs, cache prose, process line
- **ci.yml.** The header comment names all three check names. The cache comment now says four build keys across six job-lanes.
- **Contract-test prose.** The `@build_cache_jobs` reason, the `cache_miss_guards` comment and the fixture row now say "every lane".
- **New D-17 doc test.** It asserts the tested-on phrases in README, mix.exs, CONTRIBUTING and ci.yml.
- **CONTRIBUTING.** New toolchain paragraph; the removed-proof bullets and cache table now say "every lane"; new four-keys/six-job-lanes sentence; log-field note updated.
- **README and mix.exs.** Each gains the tested-on sentence. Neither names a literal latest version.
- **Planning files.** The D-18 closeout line is in MILESTONE-GUIDE.txt, and COVERAGE.md is written.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Sigil delimiter collision in the D-17 test**
- **Found during:** Task 3 gate 2.
- **Issue:** `~s("Run test suite (latest)")` ends at the first `)`, which broke parsing of the rest of the file.
- **Fix:** Switched to `~s[...]`.
- **Commit:** 77ff2392.

**2. [Rule 3 - Blocking] ci.yml header-comment wrap**
- **Issue:** Contract assertion `ci.yml verify-test block contains "Run test suite (latest)"` requires that string on one line.
- **Fix:** Re-wrapped the comment so the string sits on one line. No assertion was weakened.
- **Commit:** 77ff2392.

**Total deviations:** 2 auto-fixed, no scope change.

## Issues Encountered
- The first `mix ci.all` run was red on `too_many_connections`, caused by another project's 78 idle connections on the shared local Postgres. Per the plan's hazard rule I re-ran once, and the re-run was green. I did not terminate the other project's connections.

## Known Stubs
None.

## Threat Flags
None. The new contracts mitigate T-220-04 and T-220-05. There is no ruleset or `ci-required` edit (T-220-06), and the prose carries no literal latest pins (T-220-07).

## Next Phase Readiness
- Plan 03 cherry-picks commit A (`77ff2392`) onto its spike branch and dispatches it. The latest row's billed-minutes estimate is still unmeasured (RESEARCH A1).
- STATE.md, ROADMAP.md and REQUIREMENTS.md are left to the orchestrator.

---
*Phase: 220-newest-toolchain-lane*
*Completed: 2026-09-28*

## Self-Check: PASSED

- FOUND: all seven files. Commit A `77ff2392` holds exactly the 5 code files and commit B `5a037db2` exactly the 2 planning files. COVERAGE.md is the one required line. `.tool-versions`, `mix.lock`, the ruleset and `bin/verify-branch-protection` are unchanged.
