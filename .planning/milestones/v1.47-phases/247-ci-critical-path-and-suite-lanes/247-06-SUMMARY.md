---
phase: 247-ci-critical-path-and-suite-lanes
plan: 06
subsystem: ci
tags: [bash, partitioned-tests, lane-scope, github-actions, contract-tests, exunit-tags]
status: complete

requires:
  - "247-05 (Run tests env block with THREADLINE_CI_LANE, timeout-minutes: 12)"
provides:
  - "D-10: bin/ci-test-partitions THREADLINE_TEST_SCOPE filter (empty/unset = every file; toolchain = drop files with a whole-line `@moduletag :repo_contract`; anything else exits 2 with usage). The dropped count goes to stdout and the step summary. The exactly-once check runs on the filtered set."
  - "D-10: self-test case (w), test scope"
  - "D-10: ci.yml `test-scope: toolchain` on the min and latest include rows only, routed as `THREADLINE_TEST_SCOPE: ${{ matrix.test-scope }}` in the Run tests env"
  - "D-09 tracer: `@moduletag :repo_contract` on test/threadline/playwright_fail_fast_contract_test.exs"
  - "Threadline.RepoContractScopeContractTest: rules doc-sentence, scope-rows, filter-literal (public checkers), each with a mutation control"
  - "CONTRIBUTING CI Coverage sentence; test_helper pointer comment (exclude binding unchanged)"
affects: [247-07, "Land B"]

actuals:
  tokens: 6100
  tasks: 2
  commits: 2
plan_head_before: 282cfd82221be21b2b5cafcc502425f2bf887e2a
plan_head_after: c391a62fb2b2733be3bf92d9c535f2f9c6a857b9

tech-stack:
  added: []
  patterns:
    - "Lane scope is file filtering before assignment, not an ExUnit exclude, so plain `mix test` stays whole"
    - "One shell variable (REPO_CONTRACT_TAG_RE) holds the tag regex; the contract parses it and requires it to equal the whole-line form of the tag"
    - "An absent matrix key renders as an empty env value, which means full scope"

key-files:
  created:
    - test/threadline/repo_contract_scope_contract_test.exs
  modified:
    - bin/ci-test-partitions
    - .github/workflows/ci.yml
    - test/threadline/playwright_fail_fast_contract_test.exs
    - test/partition_weights.txt
    - CONTRIBUTING.md
    - test/test_helper.exs

key-decisions:
  - "247-06: the self-test scope case is (w), not (t). Cases (a) to (v) were already taken after 247-05."
  - "247-06: the tagged sandbox file is added inside case (w) only and removed afterwards. The shared sandbox stays at 7 files, because case (n) needs fewer files than its 8 partitions."
  - "247-06: `test-scope: toolchain` sits directly after `otp:` in the min and latest rows. That keeps the parity contract's pg/runner and runner/next-row adjacency needles matching, so no existing control changed."
  - "247-06: rule filter-literal requires exact equality with `^[[:space:]]*` + tag + `[[:space:]]*$`, not a substring check. `:repo_contracts` contains `:repo_contract`, so a substring check would miss the plan's own mutation."
  - "247-06: rule scope-rows also checks the Run tests env routing (three mutation controls: current row scoped, latest row unscoped, env dropped)."

patterns-established:
  - "Contract needles that spell the tag are assembled at runtime (`\"@\" <> \"moduletag :\" <> \"repo_contract\"`), following the zero_skips precedent"

requirements-completed: []

coverage:
  - id: D1
    description: "Scope filter offline: unset and empty run the tagged file exactly once; toolchain drops it from every partition, passes the exactly-once check, keeps the 7 others and writes `1 repo-contract files run on the current lane only` to stdout and the summary; bogus exits 2 with usage"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "bin/ci-test-partitions --self-test case (w), on bash 5.2 and /bin/bash 3.2"
        status: pass
  - id: D2
    description: "Doc sentence, min/latest-only scope rows plus env routing, and the filter literal are contract-pinned with mutation controls"
    requirement: CI-03
    verification:
      - kind: unit
        ref: "test/threadline/repo_contract_scope_contract_test.exs (6 tests)"
        status: pass
  - id: D3
    description: "Real toolchain-scope run on ephemeral postgres:16"
    requirement: CI-03
    verification:
      - kind: integration
        ref: "THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned: `2 repo-contract files run on the current lane only`, 267 files, 4 partitions with 0 failures, exit 0"
        status: pass
  - id: D4
    description: "min/latest really drop the files on GitHub Actions (matrix.test-scope renders, current renders empty)"
    requirement: CI-03
    verification:
      - kind: other
        ref: "backstop: first CI run of Land B"
        status: unknown

duration: 35min
completed: 2026-10-26
---

# Phase 247 Plan 06: Repo-contract lane scope plumbing (D-10) Summary

**With `THREADLINE_TEST_SCOPE=toolchain`, `bin/ci-test-partitions` drops files tagged `@moduletag :repo_contract` before assigning partitions and reports how many it dropped. ci.yml sets that scope only on the min and latest lanes. A new contract test pins the CONTRIBUTING sentence, the matrix rows and the filter literal. The mechanism was proven end to end on one tracer file (plus the contract test, which is tagged too).**

BASE (recorded before Task 1): `282cfd82221be21b2b5cafcc502425f2bf887e2a`

## Performance

- **Duration:** about 35 min
- **Completed:** 2026-10-26
- **Tasks:** 2, each with its own commit
- **Files modified:** 7 (1 created)

## Accomplishments

- `run_partitions` checks `THREADLINE_TEST_SCOPE` before touching the log dir. It copies the enumeration to `enumerated.full.txt`. For `toolchain`, it writes the kept files back to `enumerated.txt` and the dropped ones to `repo-contract.txt`. Assignment and `verify_assignment` then use the filtered list. The scope is documented in the header (Lane scope section and the real-path env list) and in `usage`.
- In ci.yml, `test-scope: toolchain` is on the min and latest rows, and `THREADLINE_TEST_SCOPE: ${{ matrix.test-scope }}` sits beside `THREADLINE_CI_LANE`, with the D-10 comment above the step. The Run tests anchor is unchanged, and actionlint is clean.
- Tracer tag added to `playwright_fail_fast_contract_test.exs`, on its own line after `use ExUnit.Case`.
- `Threadline.RepoContractScopeContractTest` (async, tagged). Its checkers are public (`doc_sentence_errors/1`, `scope_rows_errors/1`, `filter_literal_errors/1`) so 247-07 can add the D-09 directions beside them. It also compiles the script's regex in PCRE and checks that it matches this file's own tag line and rejects `:repo_contracts`.
- New CONTRIBUTING `## CI Coverage` paragraph. A pointer comment in test_helper. A weights row of `39` (measured locally) in path order.

## Task Commits

1. **Task 1 (tracer): scope filter, self-test (w), ci.yml rows/env, tracer tag.** `55d14d69` (feat). Tracer gate: the automated verify was re-run (self-test on both bash versions, exactly 2 non-comment `test-scope: toolchain` lines), it passed, and expansion continued.
2. **Task 2: scope contract, docs, pointer comment, weights, toolchain run.** `c391a62f` (test)

## Verification evidence

| Check | Result |
|---|---|
| `bin/ci-test-partitions --self-test` (bash 5.2) | ok, ends `... max/min ratio, test scope)` |
| `/bin/bash bin/ci-test-partitions --self-test` (3.2) | ok |
| Contracts: repo_contract_scope, zero_skips, ci_topology, ci_coverage_doc, ci_workflow_parity, playwright_fail_fast | 93 tests, 0 failures |
| `THREADLINE_TEST_SCOPE=toolchain mix verify.test_partitioned` (ephemeral postgres:16) | `2 repo-contract files run on the current lane only`; 267 files; partitions 750/900/759/936 tests, 0 failures; max/min 1.29; exit 0 |
| Dropped files absent from every `partition-*.files` | yes (0 matches) |
| `git diff BASE..HEAD -- test/test_helper.exs`, non-comment lines | none |
| `mix verify.format`, `mix verify.credo` | clean |
| `actionlint .github/workflows/ci.yml` | clean |

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Self-test case letter and sandbox size**
- **Found during:** Task 1
- **Issue:** The plan names the case (t) and says to bump the sandbox "exactly 7" check. But (t) to (v) already exist. Also, adding a file to the shared sandbox broke case (m), because an unweighted file gets the median weight and outweighs heavy3, and case (n), because 8 files no longer leave an empty partition at N=8.
- **Fix:** The case is (w). The tagged file (weight 500) is written inside (w) and removed after it. The shared sandbox and its 7-file check are unchanged, and no existing case was weakened.
- **Commit:** 55d14d69

**2. [Rule 1 - Bug] The scope key position broke the parity contract's mutation controls**
- **Found during:** Task 2
- **Issue:** In Task 1, `test-scope` went at the end of the min and latest rows. That split the adjacency needles that `ci_workflow_parity_contract_test.exs` uses (`runner:` followed by `- lane: current`, and `pg:` followed by `runner:`), so its "deprecated runner" controls stopped changing the input.
- **Fix:** Moved `test-scope: toolchain` to directly after `otp:` in both rows. The parity test is untouched.
- **Commit:** c391a62f

**3. [Rule 2 - Correctness] Filter-literal check is exact equality, and scope-rows covers the env routing**
- A substring check would accept `:repo_contracts`, so the plan's own mutation would not go red. scope-rows also asserts the Run tests env value, with its own control.
- **Commit:** c391a62f

**4. [Rule 2 - Hermeticity] The self-test unsets THREADLINE_TEST_SCOPE**
- An outer `THREADLINE_TEST_SCOPE=toolchain` would otherwise leak into the full-scope cases.
- **Commit:** 55d14d69

## Known Stubs

None.

## Threat Flags

None. T-247-14 is mitigated in three ways: unknown scope values exit 2 (self-test (w)), rule scope-rows pins the scope to the min/latest rows only, and the exactly-once check runs on the filtered set.

## Next Phase Readiness

- 247-07 can bulk-tag files with `@moduletag :repo_contract` and add the D-09 classification directions beside the public checkers in `Threadline.RepoContractScopeContractTest`.
- The first CI run of Land B is the backstop for the GitHub-side rendering (D4).

## Self-Check: PASSED

- FOUND: bin/ci-test-partitions, .github/workflows/ci.yml, test/threadline/repo_contract_scope_contract_test.exs, test/threadline/playwright_fail_fast_contract_test.exs
- FOUND: 55d14d69, c391a62f (ancestors of HEAD)
