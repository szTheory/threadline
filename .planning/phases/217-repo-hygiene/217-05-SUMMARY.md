---
phase: 217-repo-hygiene
plan: 05
subsystem: ci
tags: [ci-required, mix-alias, wiring-contract, hyg-02]

requires:
  - phase: 217-01
    provides: "bin/verify-repo-hygiene guard (7 pattern families, scoped allowlist)"
  - phase: 217-04
    provides: "Clean baseline: bin/verify-repo-hygiene exits 0 on the full local tree before this plan wires it into CI"
  - phase: 217-02
    provides: "mix.exs alias-wiring precedent (verify.temp_leaks) this plan's ci.all edit landed around"
provides:
  - "mix verify.repo_hygiene alias in ci.all, right after verify.deps_audit"
  - "Required CI job verify-repo-hygiene (no BEAM setup, no cache) as the final entry of ci-required's needs:"
  - "test/threadline/repo_hygiene_contract_test.exs pinning the full wiring, modeled on deps_audit_contract_test.exs"
  - "CONTRIBUTING.md roster bullet, job table row, and a mix ci.all mention"
affects: []

actuals:
  tokens: 4720
  tasks: 2
  commits: 1
  plan_head_before: c6daf2ee9346273e4ddb3c0b96c7fa8947b4a048
  plan_head_after: 85b84f8535764a78771f4ade33e7b2590f5b8e5c

tech-stack:
  added: []
  patterns:
    - "bin/ guard + mix verify.* alias + CI job + roster same-commit edit, copied from bin/verify-deps-audit's five-surface wiring"
    - "No-BEAM CI job (checkout only, no erlef/setup-beam, no cache) for a pure git/bash/perl guard, matching verify-release-shape rather than verify-deps-audit"

key-files:
  created:
    - test/threadline/repo_hygiene_contract_test.exs
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md

key-decisions:
  - "The CI job runs bin/verify-repo-hygiene directly with no erlef/setup-beam and no cache (the guard needs only git, bash and perl), matching verify-release-shape's shape rather than verify-deps-audit's (which needs Mix). This keeps ci_workflow_parity_contract_test.exs's setup-beam step count at 14, unchanged."
  - "In ci.all and in the acceptance-criteria adjacency check, verify.repo_hygiene sits on the line immediately after verify.deps_audit with no intervening comment line, since the plan's own acceptance criterion greps the line directly following the deps_audit entry."
  - "The wiring contract test forbids a REPO_HYGIENE_ env-redirection surface in any workflow file (mirroring deps_audit_contract_test.exs's CR-01 HEX_* surface check) — the guard's own REPO_HYGIENE_ROOT/REPO_HYGIENE_ALLOWLIST seam is test-only and must never appear in a real workflow."

requirements-completed: [HYG-02]

coverage:
  - id: D1
    description: "mix verify.repo_hygiene alias exists, shells to bin/verify-repo-hygiene with no arguments, and sits in ci.all immediately after verify.deps_audit and before the strict compile step"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_contract_test.exs — \"ci.all includes verify.repo_hygiene exactly once, between verify.deps_audit and the strict compile\""
        status: pass
      - kind: integration
        ref: "mix verify.repo_hygiene (run directly against the full local tree)"
        status: pass
    human_judgment: false
  - id: D2
    description: "verify-repo-hygiene CI job runs bin/verify-repo-hygiene and bin/verify-repo-hygiene --self-test, carries no if:/continue-on-error/services:/actions-cache/setup-beam, is in the job-id header and ci-required's needs: as the final entry, and never appears in allowed-skips/allowed-failures"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_contract_test.exs — \"verify-repo-hygiene job exists, runs both required commands, and carries no weakening\" and \"...is in the job-id header, ci-required's needs:, and never allowed-skips\", plus 6 mutation controls"
        status: pass
      - kind: integration
        ref: "actionlint -shellcheck= (clean) and the existing ci_workflow_parity_contract_test.exs / ci_topology_contract_test.exs (unmodified, pass)"
        status: pass
    human_judgment: false
  - id: D3
    description: "No workflow file references REPO_HYGIENE_, so CI cannot redirect or narrow the scan"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_contract_test.exs — \"no workflow file references the REPO_HYGIENE_ test-only env seam\""
        status: pass
    human_judgment: false
  - id: D4
    description: "CONTRIBUTING.md roster bullet, job table row, and mix ci.all paragraph mention document verify-repo-hygiene, and ci_topology_contract_test.exs's derived-roster test passes unmodified in both drift directions"
    requirement: "HYG-02"
    verification:
      - kind: unit
        ref: "test/threadline/repo_hygiene_contract_test.exs — \"CONTRIBUTING.md roster and job table document verify-repo-hygiene\""
        status: pass
      - kind: integration
        ref: "test/threadline/ci_topology_contract_test.exs (unmodified, pass)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The gate is green end-to-end: mix ci.all passes locally with .planning/ present, and bin/verify-repo-hygiene exits 0 after the commit"
    requirement: "HYG-02"
    verification:
      - kind: integration
        ref: "mix ci.all (full local run, including the browser lane)"
        status: pass
      - kind: integration
        ref: "bin/verify-repo-hygiene (post-commit)"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-27
status: complete
---

# Phase 217 Plan 5: Wire HYG-02 Guard Into CI Summary

**`mix verify.repo_hygiene` and a no-BEAM `verify-repo-hygiene` CI job are now required in `ci-required`, pinned by a new wiring contract test modeled on `deps_audit_contract_test.exs`, landing in one same-commit roster edit alongside the CONTRIBUTING roster/table updates.**

## Performance

- **Duration:** ~50 min
- **Tasks:** 2
- **Files:** 1 created, 3 modified

## Accomplishments

- `mix.exs`: `"verify.repo_hygiene": &verify_repo_hygiene/1` alias plus `defp verify_repo_hygiene(_args)` shelling to `bin/verify-repo-hygiene` with no arguments (copied verbatim from `verify_deps_audit/1`'s shape), wired into `ci.all` on the line immediately after `verify.deps_audit`.
- `.github/workflows/ci.yml`: new `verify-repo-hygiene` job — `name: Repo hygiene (no machine-local paths)`, `runs-on: ubuntu-24.04`, `timeout-minutes: 10`, deliberately **no** `erlef/setup-beam` and **no** cache step (the guard needs only git, bash and perl; `mix verify.repo_hygiene` shells to the identical script). Steps: checkout, `bin/verify-repo-hygiene`, then `bin/verify-repo-hygiene --self-test`. Added to the job-id header comment and as the final entry of `ci-required`'s `needs:`. The two "fifteen jobs" comments were updated to "sixteen".
- `CONTRIBUTING.md`: `verify-repo-hygiene` bullet as the final entry of the `ci-required` needs roster; a `| \`verify-repo-hygiene\` |` row in the job table; "a machine-local path check" added to the `mix ci.all` description paragraph.
- `test/threadline/repo_hygiene_contract_test.exs`: 7-test wiring contract (`Threadline.RepoHygieneContractTest`) modeled on `deps_audit_contract_test.exs`'s local-helper isolation convention — job existence and both required run commands, no weakening (`if:`/`continue-on-error`/`services:`/`actions/cache`/`setup-beam`, with 6 mutation controls proving each check actually catches its target), job-id header + `ci-required` needs + never-allowed-skips (with a mutation control), no `REPO_HYGIENE_` env-redirection surface in any workflow file, `ci.all` ordering (exactly once, after `verify.deps_audit`, before the strict compile step, with a mutation control), and the CONTRIBUTING roster bullet + table row (with a mutation control). No literal home path or username appears in the test file.
- The existing `ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs`, `release_control_plane_contract_test.exs`, `clean_checkout_contract_test.exs` and `deps_audit_contract_test.exs` pass unmodified — the derived roster tests picked up the new job with zero hand-edits.
- `actionlint -shellcheck=` is clean on the edited workflow.
- Both `mix test` (full suite, 2367 tests) and `mix ci.all` (including the browser lane) are green on the local tree with `.planning/` present. `bin/verify-repo-hygiene` exits 0 after the commit: `3954 tracked text file(s) clean; 8 allowlist entries used, 0 inert`.
- Measured wall time: `bin/verify-repo-hygiene` ~1.5s + `bin/verify-repo-hygiene --self-test` ~1.4s ≈ 3s combined — far under the 10-minute timeout floor, updated in the job's comment (Task 1's draft comment guessed ~0.15s from an earlier planning estimate; the measured figure replaced it before the commit).

## Task Commits

Task 1 (`type="tracer"`) made the roster edits (`mix.exs`, `.github/workflows/ci.yml`, `CONTRIBUTING.md`) but did not commit, per the plan's explicit "leave the three files staged or unstaged, make the single commit in Task 2" instruction — no separate Task 1 commit exists.

1. **Task 2: Wiring contract test + the single same-commit roster commit** - `85b84f85` (ci)

**Plan metadata:** captured in this SUMMARY commit.

_Two tasks, one commit — matching the plan's explicit same-commit roster rule (`type="auto" tdd="true"` Task 2 is where the commit happens; Task 1 is a tracer with no independent commit)._

## Files Created/Modified

- `mix.exs` — `verify.repo_hygiene` alias, `defp verify_repo_hygiene/1`, `ci.all` insertion
- `.github/workflows/ci.yml` — `verify-repo-hygiene` job, header list entry, `ci-required` needs: entry, "fifteen"→"sixteen" comment updates
- `CONTRIBUTING.md` — roster bullet, job table row, `ci.all` paragraph mention
- `test/threadline/repo_hygiene_contract_test.exs` — 7-test wiring contract, no committed literal home path or username

## Decisions Made

See `key-decisions` in the frontmatter: the no-BEAM job shape (matching `verify-release-shape`, not `verify-deps-audit`), the exact line adjacency of `verify.repo_hygiene` after `verify.deps_audit` in `ci.all`, and the `REPO_HYGIENE_` env-surface prohibition in the new contract test.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `ci.all`'s inline comment broke the plan's own line-adjacency acceptance check**
- **Found during:** Task 1 (wiring `ci.all`)
- **Issue:** The plan text asked for a comment ("cheap, no network or compile, runs early") between `"verify.deps_audit",` and `"verify.repo_hygiene",`. Placed on its own line, the comment sat between the two entries, which broke the plan's own acceptance criterion (`grep -A1 '"verify.deps_audit",' mix.exs | grep -c verify.repo_hygiene` must print `1` — i.e. `"verify.repo_hygiene",` must be the literal next line).
- **Fix:** Dropped the standalone comment; `"verify.repo_hygiene",` now sits directly on the line after `"verify.deps_audit",` with no intervening comment.
- **Files modified:** mix.exs
- **Verification:** Ran the exact acceptance-criteria grep — both the `ci.all`-block occurrence count and the adjacency check print `1`.
- **Committed in:** `85b84f85`

**2. [Rule 1 - Bug] The wiring test's `~s(...)` sigils containing nested parens tripped `mix format`'s parser**
- **Found during:** Task 2, `mix format --check-formatted` on the new test file
- **Issue:** `~s(Mix.shell().cmd("bin/verify-repo-hygiene", ["--extra"]))` (used to build a non-vacuity mutation fixture) produced `MismatchedDelimiterError` from the Elixir formatter/parser even though the parens are balanced by manual count.
- **Fix:** Replaced both `~s(...)` sigils with plain double-quoted strings (`"Mix.shell().cmd(\"bin/verify-repo-hygiene\")"` etc.), avoiding the sigil-delimiter path entirely.
- **Files modified:** test/threadline/repo_hygiene_contract_test.exs
- **Verification:** `mix format --check-formatted` clean; `mix test test/threadline/repo_hygiene_contract_test.exs` — 7 tests, 0 failures.
- **Committed in:** `85b84f85`

**3. [Rule 1 - Bug] The self-test-surface non-vacuity assertion double-counted a token `Enum.uniq()` collapses**
- **Found during:** Task 2, first run of the new contract test
- **Issue:** `forbidden_hygiene_surface/1`'s synthetic-positive test asserted `== ["REPO_HYGIENE_", "REPO_HYGIENE_"]` for a fixture containing the token twice, but the helper (correctly) applies `Enum.uniq()`, so it returns `["REPO_HYGIENE_"]`.
- **Fix:** Corrected the assertion to `== ["REPO_HYGIENE_"]`.
- **Files modified:** test/threadline/repo_hygiene_contract_test.exs
- **Verification:** `mix test test/threadline/repo_hygiene_contract_test.exs` — 7 tests, 0 failures.
- **Committed in:** `85b84f85`

---

**Total deviations:** 3 auto-fixed (3 bugs, all Rule 1)
**Impact on plan:** All three were required for the plan's own stated acceptance criteria or verify commands to pass. No scope creep — all three fixes stayed inside the two files the plan already touched.

## Issues Encountered

The first full `mix ci.all` run failed with Postgres `too_many_connections` (85/100 connections in use, 78 of them held by an unrelated concurrently-running project's `rindle_test` database on the same shared local Postgres instance — confirmed via `pg_stat_activity`, not caused by any change in this plan). Per the plan's own "if the full suite fails for a reason unrelated to this plan, re-run once" allowance (stated for the `mix test` step, applied here to the same class of environmental flake), a retry succeeded cleanly: full `mix test` (2367 tests, 0 failures) and `mix ci.all` (including the browser lane: 316 passed, 2 flaky-but-eventually-passing, 26 skipped, 0 hard failures — matching this repo's documented pre-existing browser-lane baseline) both green.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- HYG-02 is closed: `verify-repo-hygiene` is a required, contract-pinned `ci-required` gate. A PR adding a machine-local path now fails `CI required` through this job.
- Phase 217 (Repo Hygiene) is now complete: 217-01 (guard script), 217-02 (HYG-03 temp-leak check), 217-03 (verification-only), 217-04 (HYG-01 forward scrub), 217-05 (HYG-02 CI wiring, this plan) all summarized.
- No blockers. `.planning/config.json` was neither edited nor staged by this plan.

---
*Phase: 217-repo-hygiene*
*Completed: 2026-09-27*

## Self-Check: PASSED

- `test/threadline/repo_hygiene_contract_test.exs` found on disk.
- Commit `85b84f85` found in `git log --oneline --all`.
- `mix test test/threadline/repo_hygiene_contract_test.exs` — 7 tests, 0 failures.
- `actionlint -shellcheck=` — clean.
- `mix ci.all` — full local run green, including the browser lane.
- `bin/verify-repo-hygiene` (post-commit) — exit 0, `3954 tracked text file(s) clean; 8 allowlist entries used, 0 inert`.
- `git show --name-only --format= HEAD` sorted == `.github/workflows/ci.yml CONTRIBUTING.md mix.exs test/threadline/repo_hygiene_contract_test.exs` (exact match).
- `git show --name-only --format= HEAD -- test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs` — empty (derived contracts unmodified).
- `commits: 1` measured via `git rev-list --count c6daf2ee..85b84f85` (matches `actuals.commits`; `c6daf2ee` is the commit immediately preceding this plan's own work, not 217-04's `plan_head_after`, since an intervening orchestrator tracking commit landed between the two plans).
