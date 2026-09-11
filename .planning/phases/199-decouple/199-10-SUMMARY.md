---
phase: 199-decouple
plan: "10"
subsystem: testing
tags: [repository-hygiene, gitignore, formatter, exunit, tdd]

requires:
  - phase: 199-decouple
    provides: "D-17 through D-20 constraints for producer-owned ignores and child-aware formatting"
provides:
  - "anchored crash, Hex archive, Dialyzer PLT, Playwright, and critic-score ignore rules"
  - "trackability controls for reviewed snapshots, immutable fixtures, source, local config, and prefix-confusion paths"
  - "recursive formatter ownership contract with uncovered and overlap mutations"
  - "root-to-child formatter delegation for bench and the Phoenix example"
affects: [DECOUPLE-05, DECOUPLE-06, clean-checkout-proof, dialyzer-cache, contributor-dx]

actuals:
  tokens: 4243
  tasks: 2
  commits: 4
plan_head_before: becbbf46bdb8616e85d95c0fef46cae11aa6f704

tech-stack:
  added: []
  patterns:
    - "git check-ignore -v contracts bind generated probes to exact producer-owned patterns"
    - "formatter owners are discovered recursively from subdirectories and inputs in live .formatter.exs files"
    - "mutation controls prove both uncovered and overlapping formatter paths fail"

key-files:
  created:
    - test/threadline/clean_checkout_contract_test.exs
    - test/threadline/formatter_topology_contract_test.exs
  modified:
    - .gitignore
    - .formatter.exs
    - bench/.formatter.exs
    - examples/threadline_phoenix/.formatter.exs
    - bench/audit_capture_bench.exs
    - bench/bench_helper.exs
    - bench/redaction_and_changed_from_bench.exs

key-decisions:
  - "PLT policy ignores only files ending in .plt or .plt.hash beneath the anchored .dialyzer producer root; no global extension or whole-directory rule is used."
  - "The root formatter delegates bench and examples/threadline_phoenix while each child preserves its own imports and nested migration ownership."
  - "Newly owned benchmark entrypoints are formatted in the same change that makes them part of the required formatter surface."

patterns-established:
  - "Ignore policy contract: each generated probe must report the intended gitignore source pattern, and every negative control must remain unignored."
  - "Formatter topology contract: derive owner file sets from evaluated formatter inputs, then require exactly one owner per representative path."

requirements-completed: [DECOUPLE-05, DECOUPLE-06]

coverage:
  - id: D1
    description: "Generated crash, archive, PLT, Playwright, and critic-score probes map to narrow producer-owned ignore rules while reviewed and similarly named paths remain trackable."
    requirement: DECOUPLE-05
    verification:
      - kind: integration
        ref: "test/threadline/clean_checkout_contract_test.exs#generated output is ignored by its exact producer-owned rule"
        status: pass
      - kind: integration
        ref: "test/threadline/clean_checkout_contract_test.exs#reviewed evidence, source, local config, and prefix-confusion paths remain trackable"
        status: pass
    human_judgment: false
  - id: D2
    description: "Root, bench, Phoenix example, Storybook, private-script, seed, and nested-migration representatives have exactly one recursively derived formatter owner."
    requirement: DECOUPLE-06
    verification:
      - kind: integration
        ref: "test/threadline/formatter_topology_contract_test.exs#repository formatter configs give representative Elixir files exactly one owner"
        status: pass
      - kind: other
        ref: "mix format --check-formatted run independently in bench and examples/threadline_phoenix"
        status: pass
    human_judgment: false
  - id: D3
    description: "In-memory uncovered and overlapping formatter mutations both produce exact ownership errors."
    requirement: DECOUPLE-06
    verification:
      - kind: unit
        ref: "test/threadline/formatter_topology_contract_test.exs ownership_errors mutation controls"
        status: pass
    human_judgment: false

duration: 7min
completed: 2026-09-11
status: complete
---

# Phase 199 Plan 10: Narrow Generated-Output and Formatter Ownership Summary

**Exact producer-root ignores now preserve reviewed evidence, while recursive formatter configuration gives root, benchmark, Phoenix-example, Storybook, private-script, and migration files one tested owner.**

## Performance

- **Duration:** 7 min
- **Started:** 2026-09-11T05:02:20Z
- **Completed:** 2026-09-11T05:09:06Z
- **Tasks:** 2
- **Files modified:** 9 production/test files

## Accomplishments

- Replaced unanchored crash and Hex build patterns with root-anchored rules, added narrow `.dialyzer/*.plt` and `.plt.hash` coverage, and made the entire Playwright artifact producer root generated without hiding reviewed snapshots.
- Moved the critic-score ignore contract to its test-owned fixture destination with a `.gitkeep` exception, while leaving `.tool-versions`, source, immutable fixtures, and prefix-confusion paths trackable.
- Added recursive live-config formatter ownership tests with positive controls that reject both an injected parent/child overlap and a deliberately uncovered benchmark entrypoint.
- Delegated root formatting to `bench` and `examples/threadline_phoenix`, extended child inputs to benchmark entrypoints, Storybook, and private scripts, and preserved the example migration formatter/import boundaries.

## Task Commits

1. **Task 1 RED: failing generated-output policy contract** — `d3a7f5d6` (test)
2. **Task 1 GREEN: narrow producer-owned ignore policy** — `68fa01a2` (feat)
3. **Task 2 RED: failing recursive formatter ownership contract** — `2223d9dd` (test)
4. **Task 2 GREEN: child-aware formatter ownership and newly covered source formatting** — `a66f1e65` (feat)

**Plan metadata:** committed separately before sequential STATE/ROADMAP synchronization.

## Files Created/Modified

- `test/threadline/clean_checkout_contract_test.exs` — `git check-ignore` rule-identity, negative-trackability, exception, and prefix-confusion controls.
- `.gitignore` — exact crash/archive/PLT/Playwright/critic-output producer rules.
- `test/threadline/formatter_topology_contract_test.exs` — recursive owner discovery plus uncovered/overlap mutation teeth.
- `.formatter.exs` — bench/example delegation and root scripts coverage.
- `bench/.formatter.exs` — benchmark-root entrypoint coverage without changing child ownership.
- `examples/threadline_phoenix/.formatter.exs` — Storybook and private-script inputs while preserving imports, seeds, and migration subdirectories.
- `bench/audit_capture_bench.exs`, `bench/bench_helper.exs`, and `bench/redaction_and_changed_from_bench.exs` — mechanically formatted when the child formatter began owning these root entrypoints.

## Decisions Made

- PLTs are ignored by exact file suffixes beneath the anchored `.dialyzer` producer root, not by a global `*.plt` pattern or a blanket directory ignore.
- Existing e2e-local ignore rules remain the nearest owner for Playwright reports; the repository root owns the new catch-all artifact-root rule. The contract checks the rule Git actually selects rather than duplicating policy in prose.
- Formatter ownership is calculated from each live formatter configuration's `inputs` and recursively expanded `subdirectories`; the test does not maintain a separate owner-name roster.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Replaced unsupported `mix test -x` verification syntax**

- **Found during:** Task 1 RED execution.
- **Issue:** The installed Mix task rejects `-x` before ExUnit discovers tests, so the literal plan command cannot provide valid RED or GREEN evidence.
- **Fix:** Used `--max-failures 1`, the supported fail-fast equivalent, for both focused test files.
- **Files modified:** None beyond the planned tests.
- **Verification:** Both RED records returned `RED_EVIDENCE_OK`; the final focused run passed 3/3 tests.
- **Commits:** `d3a7f5d6`, `68fa01a2`, `2223d9dd`, `a66f1e65` as the guarded RED/GREEN work.

**2. [Rule 2 - Missing Critical] Formatted newly owned benchmark entrypoints**

- **Found during:** Task 2 GREEN verification.
- **Issue:** Extending the bench child config correctly exposed three previously unowned benchmark files whose current bytes did not satisfy the formatter.
- **Fix:** Ran the bench child formatter over those newly owned entrypoints in the same atomic GREEN change.
- **Files modified:** `bench/audit_capture_bench.exs`, `bench/bench_helper.exs`, `bench/redaction_and_changed_from_bench.exs`.
- **Verification:** A full `mix format --check-formatted` from `bench/` passes.
- **Commit:** `a66f1e65`.

**3. [Rule 3 - Blocking] Reconciled Phase 199 roadmap progress after the canonical handler declined the legacy layout**

- **Found during:** Sequential state synchronization after the SUMMARY commit.
- **Issue:** `roadmap.update-plan-progress 199` found 14 plans and six summaries but returned `missing_phase_details`, leaving the Plan 10 checklist and `5/14` progress row stale.
- **Fix:** Marked only `199-10-PLAN.md` complete and advanced the Phase 199 progress row to `6/14 In Progress`, matching the handler's live counts.
- **Files modified:** `.planning/ROADMAP.md`; the deviation is also registered in `.planning/WINDOWS.md`.
- **Verification:** The Plan 10 checklist is checked, the progress row reads `6/14`, and the remaining eight plans stay unchecked.

---

**Total deviations:** 3 auto-fixed (2 blocking tooling/layout issues, 1 required newly-owned formatting repair).
**Impact on plan:** The execution deviations strengthen the intended checks and reconcile metadata without broadening ignore scope or changing benchmark behavior.

## TDD Gate Compliance

- **Task 1 RED:** `d3a7f5d6`; the generated-output assertion failed because `erl_crash.dump` selected the unanchored legacy rule. The GSD evidence checker returned `RED_EVIDENCE_OK`.
- **Task 1 GREEN:** `68fa01a2`; the ignore contract passed 2/2, then the auto-mode tracer feedback rerun passed 2/2 before Task 2 began.
- **Task 2 RED:** `2223d9dd`; the formatter topology assertion failed because the root config exposed no child subdirectories. The GSD evidence checker returned `RED_EVIDENCE_OK`.
- **Task 2 GREEN:** `a66f1e65`; recursive ownership, overlap, and uncovered controls passed, and both child formatter checks passed.
- **REFACTOR:** No separate refactor commit was needed; each GREEN implementation remained direct and test-driven.

## Issues Encountered

- Repository-wide `mix format --check-formatted` reaches the new child configurations but remains red on four pre-existing root tests: `e2e_preflight_contract_test.exs`, `phase198_automation_policy_test.exs`, `phase198_nyquist_contract_test.exs`, and `main_ci_observer_contract_test.exs`. This exact drift was already registered by Plan 199-01 in `deferred-items.md`; none of those files was modified here. The two plan-owned tests, root formatter config, full bench child, and full Phoenix-example child are formatter-clean.
- The checkout has no active asdf Elixir/Erlang selection. Verification used installed Elixir `1.19.5-otp-27` and Erlang `27.3.4.15` through command-scoped environment variables without modifying the user's untracked `.tool-versions`.
- Narrowing the critic-score rule to the future test-owned producer root intentionally leaves existing operator-local `.planning/critic-scores/` output visible as untracked data. Those files were neither deleted nor staged; shared ignore policy was not widened to launder one workstation's state.

## User Setup Required

None.

## Next Phase Readiness

- Plan 199-11 can exercise the anchored ignore policy in a disposable committed checkout.
- Plan 199-08 can move the critic-score skeleton and flip writers to the already-protected test-owned output root.
- Plan 199-13 can adopt `.dialyzer` knowing only produced PLT and hash files are ignored.
- The existing four-file root formatter drift remains owned by the earlier Phase 199 deferred-item entry.

## Self-Check: PASSED

- Both created contract tests and all four formatter/ignore configuration files exist.
- Commits `d3a7f5d6`, `68fa01a2`, `2223d9dd`, and `a66f1e65` resolve as commit objects and preserve RED-before-GREEN ordering for both tasks.
- Final focused verification passes 3 tests with zero failures; root plan-owned files, the full bench child, and the full Phoenix-example child are formatter-clean.
- `git diff --check` passes, and no stub, skipped test, new network/auth/schema boundary, or user-owned scratch deletion was introduced.

---
*Phase: 199-decouple*
*Completed: 2026-09-11*
