---
phase: 215-supply-chain-gate
plan: 04
subsystem: infra
tags: [hex, mix, ci, supply-chain, deps-health, bash, tdd, doc-contract]

requires:
  - phase: 215-supply-chain-gate
    provides: "bin/verify-deps-audit's canonical dir literal, MIN_HEX floor, and MIX_BIN test seam (215-02); the hex_audit_ignores/0 convention (215-03)"
provides:
  - "bin/deps-health-report: rank-based classifier (advisory > unknown > outdated > clean) over the three lockfiles, MIX_BIN test seam, 60000-byte-capped report body"
  - ".github/workflows/deps-health.yml: weekly (Mondays 08:00 UTC) + manual-dispatch, non-required lane upserting exactly one ci-deps issue via unmodified bin/upsert-ci-issue"
  - "CONTRIBUTING.md '## Dependency freshness policy' section documenting batched release-train updates, the no-Dependabot-PR rule, the verify-deps-audit gate, the weekly lane, the hex_audit_ignores/0 convention (SUP-03's contributor-facing half), and the not-adopted Hex cooldown decision"
  - "test/threadline/deps_health_doc_contract_test.exs: derives the lane's facts from source and binds them to the CONTRIBUTING.md section, plus lane structural safety guards"
affects: []

actuals:
  tokens: 9000
  raw_tokens: 9000
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "classification logic extracted into a standalone bash script (bin/deps-health-report) with a MIX_BIN seam, same idiom as bin/classify-flake-run and bin/verify-deps-audit, so the full behavior matrix is testable offline via a fake mix binary"
    - "rank-based classification (numeric max over clean/outdated/unknown/advisory) rather than a hand-written precedence case statement, so 'a real advisory always outranks an unrelated unknown' holds by construction"
    - "doc-contract test derives every fact (cron, label, canonical dirs) from source via regex and asserts it appears in CONTRIBUTING.md, rather than restating literals — proven red-capable by a deliberate, reverted CONTRIBUTING.md edit"

key-files:
  created:
    - bin/deps-health-report
    - .github/workflows/deps-health.yml
    - test/threadline/deps_health_report_test.exs
    - test/threadline/deps_health_doc_contract_test.exs
  modified:
    - CONTRIBUTING.md

key-decisions:
  - "Rank-based classification (RANK_NAMES array + a monotonic bump() over clean=0/outdated=1/unknown=2/advisory=3) instead of a case-statement precedence table, matching the plan's exact wording ('a real advisory outranks unknown') without a bespoke combinator per pairwise case"
  - "A per-directory deps.get failure skips that directory's hex.audit/hex.outdated entirely (never invoked, not merely ignored) — mirrors bin/verify-deps-audit's own 'a vacuous audit over unfetched deps is not trusted' behavior, and is asserted in the test via a CALL_LOG that hex.audit/hex.outdated were never invoked for that dir"
  - "Discovered and fixed a `set -e` leak: the per-directory loop toggles `set -e` on around each command substitution that must survive a non-zero mix exit, and the LAST iteration leaves it ON — which turned the intentional SIGPIPE from the truncation pipeline's `head -c` into a premature script abort (exit 141) on the oversized-body test. Fixed with an explicit `set +e` immediately after the loop, restoring the script's baseline (errexit-off) mode before the truncation logic runs."
  - "Truncation implemented via full-body-then-head-c rather than incremental byte counting per section — simpler and correct because bin/deps-health-report's own report is small in the non-oversized case (well under the 60000-byte cap), so building the full string in memory first is not a real-world cost"
  - "The 'Dependency freshness policy' section inserted immediately before '## CI parity and `act`' (i.e. immediately after the `ci-required` needs: roster's closing paragraph), per the plan's exact placement instruction, so the roster section's own parse boundary (next `## ` heading) is unaffected"

requirements-completed: [SUP-04, SUP-03]

coverage:
  - id: D1
    description: "bin/deps-health-report classifies all three lockfiles (rank-based: advisory > unknown > outdated > clean), and .github/workflows/deps-health.yml wires it to exactly one ci-deps issue upsert with least-privilege permissions, proven via 13 offline tests through a fake MIX_BIN plus the workflow's own YAML-parse and shape assertions"
    requirement: "SUP-04"
    verification:
      - kind: unit
        ref: "test/threadline/deps_health_report_test.exs -- 13 tests, 0 failures"
        status: pass
      - kind: unit
        ref: "test/threadline/ci_workflow_parity_contract_test.exs test/threadline/release_control_plane_contract_test.exs -- no regression, part of the same 33-test run"
        status: pass
      - kind: other
        ref: "acceptance-criteria greps (cron count, workflow_dispatch count, LABEL count, upsert-ci-issue count, cancel-in-progress count, zero workflow-level issues:write, zero ci.yml deps-health mentions, unmodified bin/upsert-ci-issue) -- all pass"
        status: pass
    human_judgment: false
  - id: D2
    description: "CONTRIBUTING.md states the batched dependency freshness policy (no Dependabot version-update PRs, the verify-deps-audit gate, the weekly deps-health lane, the hex_audit_ignores/0 convention, the not-adopted Hex cooldown decision) with zero planning-vocabulary leakage, in the correct document position"
    requirement: "SUP-04, SUP-03"
    verification:
      - kind: unit
        ref: "test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs -- 34 tests, 0 failures (roster/parity/coverage contracts unaffected by the insert)"
        status: pass
      - kind: other
        ref: "acceptance-criteria greps: heading count = 1, all 11 required terms present in the section, zero Phase/SUP-0/D-NN matches, heading ordered after the roster and before '## CI parity and act'"
        status: pass
    human_judgment: false
  - id: D3
    description: "test/threadline/deps_health_doc_contract_test.exs derives the lane's schedule/label/lockfile facts from source and fails if the CONTRIBUTING.md section drops one; the lane's structural safety (no workflow-level write, issues:write scoped to the job, cancel-in-progress:false, no Dependabot config, non-required in both ci-required's needs: and the branch-protection ruleset, label distinct from ci-flake/ci-browser-full) is proven"
    requirement: "SUP-04"
    verification:
      - kind: unit
        ref: "test/threadline/deps_health_doc_contract_test.exs -- 15 tests, 0 failures"
        status: pass
      - kind: other
        ref: "deliberate-break run: removed the '0 8 * * 1' mention from CONTRIBUTING.md, confirmed exactly the cron test failed (14/15), restored via git checkout -- CONTRIBUTING.md, re-confirmed 15/15 green"
        status: pass
      - kind: integration
        ref: "mix test (full suite) -- 9 properties, 2270 tests, 0 failures, 2 excluded; mix verify.format -- exit 0; mix verify.credo -- 4024 mods/funs, no issues; bin/verify-deps-audit --self-test -- ok; mix verify.deps_audit -- 3 lockfiles clean (Hex 2.5.1); mix ci.all -- exit 0 (browser lane 318 passed/26 skipped/0 failed, Dialyzer clean); check-project-baseline.sh -- exit 0"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-09-26
status: complete
---

# Phase 215 Plan 04: Weekly Dependency Health Lane and Freshness Policy Summary

**A weekly, non-required `deps-health.yml` lane upserts a single `ci-deps` issue via a rank-classified `bin/deps-health-report` over all three lockfiles, and CONTRIBUTING.md now states the batched freshness policy — closing SUP-04 and SUP-03's contributor-facing half.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-09-26 (same session, after 215-01/215-02/215-03)
- **Completed:** 2026-09-26
- **Tasks:** 3 completed
- **Files modified:** 5 (4 created, 1 modified)

## Accomplishments
- `bin/deps-health-report`: a standalone bash classifier (canonical dirs `. bench examples/threadline_phoenix`, identical literal to `bin/verify-deps-audit`) that runs `mix deps.get` per directory, then (only on a successful fetch) `mix hex.audit` and `mix hex.outdated`, and classifies the overall run via a numeric-rank max (`clean`=0, `outdated`=1, `unknown`=2, `advisory`=3) so a real advisory anywhere always outranks an unrelated fetch failure elsewhere.
- The report body (`<out-dir>/report.md`) has one `## <dir>` section per canonical directory in fixed order, each with fetch/audit/outdated exit codes and ANSI-stripped output, capped at 60000 bytes with a `(truncated)` marker when oversized — proven via a fake-mix test that forces a >100KB `hex.audit` output.
- `GITHUB_OUTPUT` gets `classification=<value>` and `report=<path>` appended (never overwritten — existing content preserved), and `classification=<value>` is always echoed to stdout; the script always exits 0 — reporting is not the verdict, the workflow's own fail step decides.
- `.github/workflows/deps-health.yml`: `workflow_dispatch` + weekly `schedule` (`0 8 * * 1`, Mondays 08:00 UTC), workflow-level `permissions: contents: read` with `issues: write` scoped only to the `deps-health` job, a static `concurrency: {group: deps-health, cancel-in-progress: false}` group so overlapping runs serialize, and an upsert step that reuses `bin/upsert-ci-issue` completely unmodified (label `ci-deps`, color `FBCA04`, distinct from `ci-flake` D93F0B and `ci-browser-full` B60205). The fail step exempts only `clean` and `outdated`, so an empty/crashed report step (with a fallback body naming the run URL) still files an issue and fails the job — never green by omission.
- `test/threadline/deps_health_report_test.exs`: 13 fully offline tests through a fake `MIX_BIN` covering the full classification behavior table (clean, outdated-only, advisory-even-with-outdated, unknown-on-fetch-failure with proof that the failed dir's audit/outdated were never invoked, advisory-outranks-unknown-elsewhere), the report body's section structure and truncation cap, `GITHUB_OUTPUT` append semantics, and five workflow-shape assertions (report step id, upsert step's `if:` gate, fail step's exemption set, title/marker consistency, and a real `YamlElixir` parse of the workflow).
- CONTRIBUTING.md's new `## Dependency freshness policy` section (inserted immediately before `## CI parity and \`act\``, after the `ci-required` needs: roster) states, in the plan's specified order: batched release-train updates; the exact sentence `This repository does not use Dependabot version-update pull requests.`; the required `verify-deps-audit` gate; the weekly non-required `deps-health.yml` lane and when it goes red vs. merely reports; the `hex_audit_ignores/0` accountability convention (documenting plan 03's SUP-03 mechanism where contributors actually look); the not-adopted Hex `cooldown` decision; and a closing non-vacuous-doc-trust note.
- `test/threadline/deps_health_doc_contract_test.exs`: 15 tests deriving the cron schedule, the `ci-deps` label, and the canonical lockfile-directory literal from `.github/workflows/deps-health.yml` and `bin/deps-health-report`/`bin/verify-deps-audit` (asserting the two scripts' literals are identical), and asserting each derived fact appears in the CONTRIBUTING.md section — plus structural safety guards (no workflow-level write permission, `issues: write` present at job level, `cancel-in-progress: false`, `bin/upsert-ci-issue` usage, no `.github/dependabot.yml`/`.yaml`, the `ci-deps` label distinct from every other in-repo workflow's `LABEL:` value, the `deps-health` job id absent from `ci-required`'s `needs:`, and the `Dependency Health` job name absent from `.github/rulesets/main.json`).
- Proved the doc-contract test is red-capable, not vacuous: temporarily removed the `0 8 * * 1` mention from CONTRIBUTING.md, confirmed exactly the cron-derivation test failed (14/15, all others unaffected), then restored via `git checkout -- CONTRIBUTING.md` and re-confirmed 15/15 green.
- Full regression proof: `mix test` (2270 tests, 0 failures, 2 excluded), `mix verify.format`, `mix verify.credo` (4024 mods/funs, no issues), `bin/verify-deps-audit --self-test` (ok), `mix verify.deps_audit` (3 lockfiles clean, Hex 2.5.1), `mix ci.all` (exit 0 — browser lane 318 passed / 26 skipped / 0 failed, matching the CLAUDE.md-documented baseline exactly; Dialyzer ran clean with no PLT-cache-miss issue), and Phase 214's `check-project-baseline.sh` (exit 0).
- `git diff --quiet 36ab6e71 -- bench/mix.exs examples/threadline_phoenix/mix.exs` confirmed clean — no dependency constraint was touched anywhere in this plan.

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — bin/deps-health-report classifies three lockfiles, and deps-health.yml wires it to one ci-deps issue** - `580f876c` (ci)
2. **Task 2: CONTRIBUTING "## Dependency freshness policy" section** - `1d27c2d5` (docs)
3. **Task 3: Doc-contract test binding deps-health.yml and the gate to the freshness policy, plus lane structural guards** - `c86b820e` (test)

**Plan metadata:** commit follows this SUMMARY.

## Files Created/Modified
- `bin/deps-health-report` - the classifier script (executable, MIX_BIN seam, rank-based classification, 60000-byte-capped report body)
- `.github/workflows/deps-health.yml` - weekly + manual-dispatch, non-required lane, single ci-deps issue upsert, least-privilege permissions
- `test/threadline/deps_health_report_test.exs` - 13 offline tests via a fake `mix`, plus workflow-shape assertions
- `test/threadline/deps_health_doc_contract_test.exs` - 15-test derive-and-bind contract plus structural safety guards
- `CONTRIBUTING.md` - new `## Dependency freshness policy` section

## Decisions Made
- Classification implemented as a numeric-rank max (`clean`=0 < `outdated`=1 < `unknown`=2 < `advisory`=3) rather than a hand-written case-statement precedence table — makes "advisory always outranks an unrelated unknown" hold by construction rather than by exhaustive case enumeration.
- A directory whose `deps.get` fails skips `hex.audit`/`hex.outdated` entirely for that directory (never invoked, not merely ignored) — mirrors `bin/verify-deps-audit`'s own "a vacuous audit over unfetched deps is not trusted" rule, verified via a call-log assertion in the test.
- Discovered and fixed a `set -e` leak in the per-directory loop: each command-substitution capture toggles `set -e` back ON after temporarily disabling it, and the LAST loop iteration leaves it ON for the rest of the script — which turned the deliberate SIGPIPE from `head -c`'s early pipe close (during body truncation) into a premature script abort (exit 141) on the oversized-report test. Fixed with an explicit `set +e` immediately after the loop, restoring the script's baseline errexit-off mode before the truncation logic runs.
- Built the full report body in memory before truncating (`head -c $KEEP`) rather than tracking byte budget incrementally per section — simpler, and correct because the non-oversized case (the overwhelming majority of real runs) is well under the 60000-byte cap.
- The CONTRIBUTING.md section was inserted immediately before `## CI parity and \`act\`` (right after the `ci-required` needs: roster's closing paragraph), matching the plan's exact placement instruction and leaving the roster section's own next-heading parse boundary untouched.

## Deviations from Plan

None - plan executed exactly as written, including the RED-first TDD sequencing for Task 1 (test file written and confirmed failing — script absent, 13/13 failures — before `bin/deps-health-report` was created) and Task 3's explicit red-capability proof (deliberate CONTRIBUTING.md break, confirmed single targeted test failure, restore via `git checkout --`).

## Issues Encountered
- The `set -e` leak described above (Decisions Made) surfaced as an unexpected exit-141 failure on the truncation test during Task 1's GREEN phase. Root-caused to the per-directory loop's `set -e`/`set +e` toggling leaving errexit ON after the final iteration, which then made the intentional SIGPIPE from the truncation pipeline's `head -c` fatal. Fixed with an explicit `set +e` after the loop; re-ran the full test file to confirm no other test depended on the previous (accidental) errexit-on state.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- SUP-04 holds: a weekly, non-required `deps-health.yml` runs `hex.audit` + `hex.outdated` over all three lockfiles and upserts a single `ci-deps` issue (label distinct from `ci-flake`/`ci-browser-full`), least-privilege (`issues: write` scoped to the job only), and CONTRIBUTING states the batched freshness policy with no Dependabot version-update PRs, doc-contract-tested and proven red-capable.
- SUP-03's `hex_audit_ignores/0` convention (from 215-03) is now documented where contributors actually look (CONTRIBUTING.md), closing its contributor-facing half.
- No `.github/dependabot.yml`/`.yaml` exists; no dependency constraint (`bench/mix.exs`, `examples/threadline_phoenix/mix.exs`, root `defp deps`) was touched by this plan.
- Phase 215 (Supply Chain Gate) is now complete: all four plans (215-01 lockfile fixes, 215-02 per-PR gate, 215-03 ignore-advisories contract, 215-04 weekly lane + docs) are done, and `mix ci.all` passes end-to-end with the new `verify-deps-audit` job included.
- No blockers for subsequent phases.

---
*Phase: 215-supply-chain-gate*
*Completed: 2026-09-26*

## Self-Check: PASSED

`bin/deps-health-report` (executable), `.github/workflows/deps-health.yml`, `test/threadline/deps_health_report_test.exs`, and `test/threadline/deps_health_doc_contract_test.exs` confirmed present on disk. All three task commits (`580f876c`, `1d27c2d5`, `c86b820e`) confirmed present in `git log`. Plan-level verification re-run: `mix test test/threadline/deps_health_report_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/release_control_plane_contract_test.exs` (33/33), `mix test test/threadline/ci_topology_contract_test.exs test/threadline/ci_workflow_parity_contract_test.exs test/threadline/ci_coverage_doc_contract_test.exs` (34/34), `mix test test/threadline/deps_health_doc_contract_test.exs test/threadline/deps_health_report_test.exs test/threadline/deps_audit_contract_test.exs test/threadline/deps_audit_gate_test.exs test/threadline/ignore_advisories_contract_test.exs` (63/63), full `mix test` (2270 tests, 0 failures), `mix verify.format` (exit 0), `mix verify.credo` (4024 mods/funs, no issues), `bin/verify-deps-audit --self-test` (ok), `mix verify.deps_audit` (3 lockfiles clean), `mix ci.all` (exit 0, browser lane 318 passed/26 skipped/0 failed), `check-project-baseline.sh` (exit 0), and all plan-listed acceptance-criteria greps re-checked and passing.
