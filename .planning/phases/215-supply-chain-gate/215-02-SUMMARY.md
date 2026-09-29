---
phase: 215-supply-chain-gate
plan: 02
subsystem: infra
tags: [hex, mix, ci, supply-chain, hex-audit, bash, tdd]

requires:
  - phase: 215-supply-chain-gate
    provides: all three lockfiles (root, bench, examples/threadline_phoenix) hex.audit-clean (215-01)
provides:
  - "bin/verify-deps-audit: the per-PR supply-chain gate (SUP-02) — Hex >= 2.5.1 floor, env-var-bypass refusal, three-lockfile deps.get + deps.unlock --check-unused + hex.audit, aggregate report, --self-test negative proof"
  - "mix verify.deps_audit alias, required verify-deps-audit CI job, ci.all membership, CONTRIBUTING documentation — all wired in one same-commit roster edit"
affects: [215-04]

actuals:
  tokens: 8500
  raw_tokens: 8500
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "gate logic in a standalone bash script (bin/verify-deps-audit) with a MIX_BIN seam, not a private mix.exs function, so the full behavior matrix is testable offline via a fake mix binary — same shape as bin/upsert-ci-issue's GH_BIN seam"
    - "--self-test subcommand as the network-backed negative proof, run as a CI job step rather than a tagged/excluded ExUnit test, keeping test/test_helper.exs untouched and every test in the default mix test lane"

key-files:
  created:
    - bin/verify-deps-audit
    - test/fixtures/deps_audit/vulnerable_lock/mix.exs
    - test/fixtures/deps_audit/vulnerable_lock/mix.lock
    - test/fixtures/deps_audit/vulnerable_lock/README.md
    - test/threadline/deps_audit_gate_test.exs
    - test/threadline/deps_audit_contract_test.exs
  modified:
    - mix.exs
    - .github/workflows/ci.yml
    - CONTRIBUTING.md

key-decisions:
  - "Followed the plan's explicit departure from the orchestrator's RESEARCH.md recommendation: gate logic lives in bin/verify-deps-audit (a bash script), not a private mix.exs function, so it is testable offline with a fake MIX_BIN"
  - "The network-backed negative proof is bin/verify-deps-audit --self-test, run as a CI job step, not a tagged ExUnit test excluded from mix test — avoids forcing a Postgres service + full test-env compile into the new job, and keeps 'no test excluded from default mix test' true"
  - "Dedupe of duplicate directory arguments uses a plain array + linear scan, not declare -A (bash 4+ associative arrays), for portability with macOS's stock /bin/bash 3.2 — no existing bin/ script in this repo uses declare -A"
  - "Per-subcommand mix calls are captured via `if var=$(cmd); then ... else status=$?; fi`, not `var=$(cmd) || true; status=$?`, because the latter always yields status 0 under set -euo pipefail (the `|| true` swallows the real exit code before $? is read)"
  - "verify.deps_audit placed in ci.all directly after verify.credo — fast, network-bound, and runs before the compile/test lanes, per the plan's explicit placement instruction"

requirements-completed: [SUP-02]

coverage:
  - id: D1
    description: "bin/verify-deps-audit + mix verify.deps_audit: Hex >= 2.5.1 floor (numeric compare), refuses HEX_IGNORE_ADVISORIES/HEX_IGNORE_RETIREMENTS before any mix call, audits root/bench/examples/threadline_phoenix in order with aggregated (non-fail-fast) reporting, proven via 15 offline tests through a fake MIX_BIN plus a live clean run and a live --self-test proving red on a known-vulnerable fixture lock and a faked old Hex"
    requirement: "SUP-02"
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_gate_test.exs -- 15 tests, 0 failures"
        status: pass
      - kind: other
        ref: "mix verify.deps_audit (live, real Hex 2.5.1, all three lockfiles) -- verify-deps-audit: 3 lockfile(s) audit clean (Hex 2.5.1), ~13s"
        status: pass
      - kind: other
        ref: "bin/verify-deps-audit --self-test (live, real network) -- verify-deps-audit self-test: ok (vulnerable lock red, old Hex red), ~4s"
        status: pass
      - kind: other
        ref: "mix format --check-formatted -- exit 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "verify-deps-audit is a required, unskippable CI job (no if:/continue-on-error/services:), listed in the job-id header and ci-required's needs: (fifteen required jobs), never in allowed-skips/allowed-failures, mirrored in ci.all exactly once and in CONTRIBUTING.md's roster and job table, wired in one same-commit edit with a contract test proving every direction of drift"
    requirement: "SUP-02"
    verification:
      - kind: unit
        ref: "test/threadline/deps_audit_contract_test.exs -- 5 tests, 0 failures (RED-first: 4/5 failed before the wiring existed)"
        status: pass
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs, ci_workflow_parity_contract_test.exs, release_control_plane_contract_test.exs -- 39 tests, 0 failures (no existing contract regressed)"
        status: pass
      - kind: integration
        ref: "mix test (full suite) -- 2242 tests, 0 failures, 2 excluded"
        status: pass
      - kind: other
        ref: "mix verify.credo -- 4010 mods/funs, found no issues"
        status: pass
    human_judgment: false

duration: ~35min
completed: 2026-09-26
status: complete
---

# Phase 215 Plan 02: Supply Chain Gate — Per-PR CI Gate Summary

**`mix verify.deps_audit` / `bin/verify-deps-audit` is now a required `verify-deps-audit` CI job asserting Hex >= 2.5.1 and auditing all three lockfiles via `hex.audit`, with a `--self-test` negative proof and a wiring contract test that fails on any weakening.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-09-26 (same session, after 215-01/215-03)
- **Completed:** 2026-09-26
- **Tasks:** 2 completed
- **Files modified:** 9 (6 created, 3 modified)

## Accomplishments
- `bin/verify-deps-audit`: a standalone bash gate (MIN_HEX literal `2.5.1`, canonical dirs `. bench examples/threadline_phoenix`) that refuses `HEX_IGNORE_ADVISORIES`/`HEX_IGNORE_RETIREMENTS` before any `mix` call, checks the Hex version floor numerically (not lexically — `2.10.0` correctly beats `2.5.1`), then runs `deps.get` + `deps.unlock --check-unused` + `hex.audit` per directory in order, aggregating failures across all three rather than stopping at the first.
- `--self-test` mode proves the gate has teeth against real `hex.pm` data: it copies a committed, deliberately vulnerable `plug 1.19.1` fixture lock into a throwaway project under the repo's gitignored `tmp/` and asserts the gate goes red **for an advisory** (not vacuously), then repeats with a faked Hex 2.4.0 and asserts the version-floor refusal runs before any audit subcommand.
- `mix verify.deps_audit` alias added to `mix.exs`, shelling to `bin/verify-deps-audit` with no arguments (CLI args ignored on purpose so the gate can't be narrowed from the command line).
- `test/threadline/deps_audit_gate_test.exs`: 15 fully offline tests through a fake `MIX_BIN`, covering the entire behavior matrix from the plan (clean run + CALL_LOG order, numeric Hex comparison at three failing versions, unparseable Hex output, aggregate-not-fail-fast on a mid-list `hex.audit` failure, `deps.unlock`/`deps.get` failures, both env-var bypasses, missing/duplicate directory arguments, and the no-args canonical-dirs-in-order case against the real repo tree).
- `verify-deps-audit` wired into `.github/workflows/ci.yml` as a required job (no Postgres service, no deps cache — the gate fetches its own three projects' deps), added to the job-id header and `ci-required`'s `needs:` (fourteen → fifteen required jobs), and `ci.all` now runs `verify.deps_audit` right after `verify.credo`.
- `test/threadline/deps_audit_contract_test.exs`: a same-commit wiring contract, written and confirmed RED first (4/5 failing before any CI/mix.exs/CONTRIBUTING edit existed), then GREEN after the wiring — asserts the job's commands, the absence of `if:`/`continue-on-error`/`services:`, header + `ci-required` membership, `allowed-skips`/`allowed-failures` exclusion, `ci.all` exactly-once membership, and that no workflow file anywhere sets either `HEX_IGNORE_*` variable.
- CONTRIBUTING.md updated: roster bullet, List 1 job table row, and a `## Run mix ci.all` prose mention.
- Full regression proof: `mix test` (2242 tests, 0 failures, 2 excluded — up from 2222 pre-plan), `mix verify.format`, `mix verify.credo` (4010 mods/funs, no issues), plus the targeted contract suites (`deps_audit_contract_test.exs`, `ci_topology_contract_test.exs`, `ci_workflow_parity_contract_test.exs`, `release_control_plane_contract_test.exs` — 44 tests, 0 failures) all green.
- `git diff 36ab6e71 -- bench/mix.exs examples/threadline_phoenix/mix.exs` is empty and the root `defp deps do` block is untouched — no dependency constraint was edited anywhere to make the gate pass.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — bin/verify-deps-audit + `mix verify.deps_audit` alias, green live on the clean tree, red on the vulnerable fixture and on faked old Hex** - `b7627b79` (ci)
2. **Task 2: Wire verify-deps-audit into CI, ci-required, CONTRIBUTING and ci.all in ONE commit, with a wiring contract test** - `83eb1cf8` (ci)

**Plan metadata:** commit follows this SUMMARY.

## Files Created/Modified
- `bin/verify-deps-audit` - the gate script (executable, MIX_BIN seam, `--self-test` mode)
- `test/fixtures/deps_audit/vulnerable_lock/mix.exs` - fixture MixProject pinning `plug == 1.19.1`
- `test/fixtures/deps_audit/vulnerable_lock/mix.lock` - fixture lock (plug + its transitive deps, from `bench/mix.lock` at base commit `36ab6e71`)
- `test/fixtures/deps_audit/vulnerable_lock/README.md` - explains the fixture and warns it must never be "fixed"
- `test/threadline/deps_audit_gate_test.exs` - 15 offline behavior tests via a fake `mix`
- `test/threadline/deps_audit_contract_test.exs` - 5-test wiring contract (job, header, needs:, allowed-skips exclusion, ci.all, CONTRIBUTING, no HEX_IGNORE_* anywhere)
- `mix.exs` - `verify.deps_audit` alias + `verify_deps_audit/1`; `ci.all` entry
- `.github/workflows/ci.yml` - `verify-deps-audit` job, job-id header, `ci-required` needs:, "fourteen"→"fifteen" comment updates
- `CONTRIBUTING.md` - roster bullet, job table row, `ci.all` prose mention

## Decisions Made
- Gate logic lives in `bin/verify-deps-audit` (bash), not a private `mix.exs` function — the plan's explicit, documented departure from RESEARCH.md's default recommendation, because a script with a `MIX_BIN` seam is testable offline while a private mix.exs function is not.
- The negative network proof is `bin/verify-deps-audit --self-test`, run as a CI job step rather than a tagged/excluded ExUnit test — avoids forcing a Postgres service and full test-env compile into the new job, and keeps `test/test_helper.exs` and the "no test excluded from default `mix test`" rule untouched.
- Dedupe of duplicate `-` directory arguments uses a plain bash array with a linear membership scan rather than `declare -A` (bash 4+ associative arrays), since no existing script in `bin/` relies on that feature and macOS ships bash 3.2 as `/bin/bash`.
- Discovered and fixed a `set -euo pipefail` pitfall while writing the per-subcommand capture: `var=$(cmd) || true; status=$?` always yields `status=0` because the `|| true` swallows `cmd`'s real exit code before `$?` is read. Used `if var=$(cmd); then status=0; else status=$?; fi` instead (a tested context, so `set -e` does not abort on the nonzero substitution, and the real status is preserved).
- `verify.deps_audit` placed in `ci.all` directly after `verify.credo`, per the plan's explicit placement rationale (fast, network-bound, before compile/test).

## Deviations from Plan

None - plan executed exactly as written, including the TDD sequencing (Task 1's gate test written and run against the finished script rather than a not-yet-existing one, since Task 1 built script and test together as one coherent artifact; Task 2's contract test was written and confirmed RED — 4/5 failing — before any CI/mix.exs/CONTRIBUTING wiring existed, then made GREEN, matching the plan's explicit red-then-green instruction for that task).

## Issues Encountered
None. Both live checks (`mix verify.deps_audit`, `bin/verify-deps-audit --self-test`) passed on the first run; measured combined wall time is ~13s + ~4s ≈ 17s, well inside the 10-minute CI job timeout (the repo's timeout floor).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUP-02 holds: a PR introducing a lockfile advisory now fails a required, unskippable CI job, proven by a live self-test against real `hex.pm` advisory data and a same-commit contract test that fails on any drift (job removal, lost command, added `if:`/`continue-on-error`/`services:`, `allowed-skips` addition, `ci.all` omission, or CONTRIBUTING doc drift).
- No `mix.exs` `defp deps do`, `bench/mix.exs`, or `examples/threadline_phoenix/mix.exs` edits were made — this plan does not conflict with 215-01's or 215-03's work.
- No blockers for 215-04 (weekly deps-health issue), which can reuse this plan's `MIN_HEX`/canonical-dirs conventions if useful.

---
*Phase: 215-supply-chain-gate*
*Completed: 2026-09-26*

## Self-Check: PASSED

`bin/verify-deps-audit` (executable), all four `test/fixtures/deps_audit/vulnerable_lock/` files, `test/threadline/deps_audit_gate_test.exs`, and `test/threadline/deps_audit_contract_test.exs` confirmed present on disk. Both task commits (`b7627b79`, `83eb1cf8`) confirmed present in `git log`. Plan-level verification re-run: `mix test test/threadline/deps_audit_gate_test.exs` (15/15), `mix verify.deps_audit` (live, exit 0), `bin/verify-deps-audit --self-test` (live, exit 0), `mix format --check-formatted` (exit 0), `mix test test/threadline/deps_audit_contract_test.exs test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/release_control_plane_contract_test.exs` (44/44), full `mix test` (2242 tests, 0 failures), `mix verify.credo` (no issues), and all nine plan-listed acceptance-criteria greps re-checked and passing.
