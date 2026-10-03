---
phase: 230-rebalance-net-suite-check-and-0-12-0
plan: "01"
subsystem: testing
tags: [exunit, doc-contract, guard-tests, ci, rubric]

requires:
  - phase: 227-db-backed-property-tests
    provides: "SC5-local.md noise-floor caveat sentence and local-median table shape, reused verbatim here"
provides:
  - "Two whole-file prose-lock doc-contract tests deleted (stg_doc_contract_test.exs, operator_surface/theme_doc_contract_test.exs)"
  - "Three mixed doc-contract files trimmed to derived/security-boundary assertions only (operator_surface_doc_contract_test.exs, operator_surface/coverage_doc_contract_test.exs, operator_surface/policy_show_doc_contract_test.exs)"
  - "CONTRIBUTING.md rubric for future doc-contract/guard tests"
  - "230-EVIDENCE.md SUITE-04 section: BASE sha, before/after wall clock, per-assertion ledger, mutation-control cross-check, ci-required roster proof"
affects: [230-02, 230-03, 230-04]

actuals:
  tokens: 12856
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Doc-contract KEEP/CUT rubric: keep assertions derived from a live source (code, generated output, a real Mix task run, git ls-files) or asserting a structural/security invariant; cut prose-to-hand-typed-literal checks; never relocate a cut assertion"

key-files:
  created:
    - .planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md
  modified:
    - CONTRIBUTING.md
    - test/partition_weights.txt
    - test/threadline/brandbook_token_parity_test.exs
    - test/threadline/support_playbook_doc_contract_test.exs
    - test/threadline/operator_surface_doc_contract_test.exs
    - test/threadline/operator_surface/coverage_doc_contract_test.exs
    - test/threadline/operator_surface/policy_show_doc_contract_test.exs

key-decisions:
  - "Route-literal integration finding: git grep confirmed non-prose integration tests (transaction_live_test.exs, actor_live_test.exs, row_history_live_test.exs, etc.) already exercise the /audit/transactions, /audit/actors and /audit/rows routes, so cutting the prose route-literal check left no deferred gap (D-03 n/a)"
  - "v1.43 mutation-control cross-check found no hit naming a mutation control on any assertion this plan cuts — the apparent hits were substring collisions with the unrelated ci_coverage_doc_contract_test.exs file"
  - "After-figure wall clock (median 151.59s) rose 14.15s over the before-figure (137.44s) despite removing 34 tests; read as within the repo's documented 52-56s local-noise floor (224-EVIDENCE.md), not a regression — CI step-sum wall clock (SUITE-06, a later plan) is the real comparator"

requirements-completed: [SUITE-04]

coverage:
  - id: D1
    description: "The two whole-file prose locks (stg_doc_contract_test.exs, operator_surface/theme_doc_contract_test.exs) are deleted, with their partition-weight lines removed and no tracked non-planning file naming them"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "test ! -e + git grep (acceptance criteria, Task 1)"
        status: pass
    human_judgment: false
  - id: D2
    description: "The doc-contract floor count is 35 (37 - 2), at or above the 30-file bin/verify-bump-rehearsal floor, and the floor script itself is untouched"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "find test ... | wc -l == 35; mix verify.bump_rehearsal"
        status: pass
    human_judgment: false
  - id: D3
    description: "operator_surface_doc_contract_test.exs, coverage_doc_contract_test.exs and policy_show_doc_contract_test.exs are line-item trimmed per the locked rubric, keeping only derived and security-boundary assertions; storage-schema files are untouched"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "mix test (5 files) --warnings-as-errors; grep assertions on Pins/Coverage.run/Show.run/export-auth; mix format + mix verify.credo"
        status: pass
    human_judgment: false
  - id: D4
    description: "CONTRIBUTING.md records the 'Writing a doc-contract or guard test' rubric in the correct position, and every CONTRIBUTING-reading test stays green"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "awk heading-order check; mix test (18 CONTRIBUTING-reading contract files) — 278 tests, 0 failures"
        status: pass
    human_judgment: false
  - id: D5
    description: "The ci-required roster (13 jobs) is byte-identical before and after, proven by an empty .github/workflows/ diff against BASE and a green ci_topology_contract_test.exs"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "diff before/after ci-required blocks; git diff BASE -- .github/workflows/; ci_topology_contract_test.exs (part of the 278/0 run)"
        status: pass
    human_judgment: false
  - id: D6
    description: "230-EVIDENCE.md reports the rebalance's own local wall clock before and after (median of 3), the ExUnit test-count delta, and a per-assertion keep/cut ledger with a one-line reason for each kept security exception"
    requirement: "SUITE-04"
    verification:
      - kind: unit
        ref: "230-EVIDENCE.md ### Wall clock before and after, ### Line-item ledger sections (manually inspected)"
        status: pass
    human_judgment: false

duration: ~1h40m
completed: 2026-10-02
status: complete
---

# Phase 230 Plan 01: Rebalance guard tests (SUITE-04) Summary

**Cut 34 prose-to-literal ExUnit assertions across five doc-contract files (2 whole files, 3 line-item trims), recorded the KEEP/CUT rubric in CONTRIBUTING.md, and proved the ci-required roster and doc-contract floor are unchanged — all before/after figures and the per-assertion ledger are in 230-EVIDENCE.md.**

## Performance

- **Duration:** ~1h40m
- **Started:** 2026-10-02T20:35:00Z (approx)
- **Completed:** 2026-10-02T22:15:00Z (approx)
- **Tasks:** 3
- **Files modified:** 9 (2 deleted, 7 modified/created)

## Accomplishments

- Deleted `test/threadline/stg_doc_contract_test.exs` (6 tests) and `test/threadline/operator_surface/theme_doc_contract_test.exs` (11 tests) whole — both were pure `File.read!` + `String.contains?` prose locks with no live derivation
- Trimmed `operator_surface_doc_contract_test.exs` 15 -> 6 tests, keeping only the `Pins.target_pin_version()`-derived install-pin assertion and the fail-closed/`:authorize_fn`/export-auth security-boundary sentences
- Trimmed `operator_surface/coverage_doc_contract_test.exs` 39 -> 32 tests, cutting the guide-only prose blocks (selected-schema readiness, storage-schema happy path, `--strict` rewording identity checks across guides, the two-guide `--all-schemas` check) and removing the now-unused `guide_section/2` helper
- Trimmed `operator_surface/policy_show_doc_contract_test.exs` 12 -> 11 tests, cutting the single domain-reference-only prose test and its `@domain_reference_path` attribute
- Recorded `### Writing a doc-contract or guard test` in CONTRIBUTING.md (KEEP 1-3, CUT shape, one-sentence-moduledoc convention), positioned correctly before "## Local-only critic"
- Proved the doc-contract floor moved 37 -> 35 against the unchanged 30-file `bin/verify-bump-rehearsal` floor, and the 13-job ci-required roster is byte-identical (empty diff both ways)
- Confirmed via `git grep` that cutting the route-literal prose check left real integration coverage in place (transaction/actor/row-history LiveView tests already exercise those routes) — no deferred gap

## Task Commits

1. **Task 1: Tracer — measure the before figure, then cut the two whole-file prose locks** - `bb2c1c47` (test)
2. **Task 2: Line-item trim the three mixed files by rubric, with a per-assertion ledger** - `77cb5c86` (test)
3. **Task 3: Record the rubric in CONTRIBUTING.md, measure the after figure, prove ci-required roster unchanged** - `bd98960f` (docs)

## Files Created/Modified

- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` - SUITE-04 rebalance evidence: BASE sha, before/after wall clock, whole-file-cut table, weight-line removal, doc-contract floor, per-assertion ledger, mutation-control cross-check, ci-required roster proof
- `CONTRIBUTING.md` - new `### Writing a doc-contract or guard test` subsection
- `test/partition_weights.txt` - removed the 2 dead weight lines for the deleted files
- `test/threadline/brandbook_token_parity_test.exs` - comment reference to the deleted theme test removed
- `test/threadline/support_playbook_doc_contract_test.exs` - comment reference to the deleted stg test removed
- `test/threadline/operator_surface_doc_contract_test.exs` - 15 -> 6 tests
- `test/threadline/operator_surface/coverage_doc_contract_test.exs` - 39 -> 32 tests, `guide_section/2` helper removed
- `test/threadline/operator_surface/policy_show_doc_contract_test.exs` - 12 -> 11 tests, `@domain_reference_path` removed
- `test/threadline/stg_doc_contract_test.exs` - deleted (6 tests)
- `test/threadline/operator_surface/theme_doc_contract_test.exs` - deleted (11 tests)

## Decisions Made

- Route-literal cut: confirmed via `git grep` that non-prose integration tests already cover `/audit/transactions/`, `/audit/actors/` and `/audit/rows/`, so no deferred gap was recorded for D-03 (coverage exists).
- v1.43 mutation-control cross-check: the apparent `grep -rl` hits on `coverage_doc_contract` were substring collisions with the unrelated `ci_coverage_doc_contract_test.exs` file; no real mutation control was found defending any assertion this plan cuts.
- The local wall-clock delta (+14.15s median, 137.44s -> 151.59s) despite removing 34 tests is read as within this machine's documented noise floor (52-56s swings per 224-EVIDENCE.md), not a regression; SUITE-06 (CI step-sum) is the actual release comparator per D-06/D-08.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- SUITE-04's rubric and cuts are complete and committed; 230-EVIDENCE.md's `## SUITE-04 rebalance` section is ready for the net-suite plan (230-02) to append its own sections without disturbing this one.
- REBAL_AFTER (`77cb5c861a186bfa7919950a08abd0e4705fbbb3`) is recorded in evidence so plan 02 can reuse the after-figure test tree state if nothing in `test/` changes before its own measurement.
- No blockers.

## Self-Check: PASSED

- `test ! -e test/threadline/stg_doc_contract_test.exs && test ! -e test/threadline/operator_surface/theme_doc_contract_test.exs` — both FOUND missing (deleted) as expected
- `git log --oneline --all --grep="230-01"` returns 3 commits (bb2c1c47, 77cb5c86, bd98960f) — FOUND
- All plan-level `<verification>` commands re-run clean during task execution (see Task 1-3 verify blocks above)
- `.planning/phases/230-rebalance-net-suite-check-and-0-12-0/230-EVIDENCE.md` exists and contains `## SUITE-04 rebalance`, `### Line-item ledger`, `### v1.43 mutation-control cross-check`, `### Wall clock before and after`, `### ci-required roster` — FOUND

---
*Phase: 230-rebalance-net-suite-check-and-0-12-0*
*Completed: 2026-10-02*
