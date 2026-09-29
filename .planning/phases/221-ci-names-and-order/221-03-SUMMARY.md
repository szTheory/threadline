---
phase: 221-ci-names-and-order
plan: 03
status: complete
subsystem: ci-contracts
tags: [ci, contracts, check-names, doc-contract, dx]
requires:
  - "221-02: parsed_job_order/1 and the D-06 job order"
provides:
  - "D-02 display names on every ci.yml job; verify-test posts Build and test (min/current/latest)"
  - "@ci_check_names, @retired_check_names, check_name_errors/2 (rules name-exact, name-static, name-verb, name-length, name-jargon, name-first-key, roster, name-retired)"
  - "evaluator_doc_errors/1 (rule evaluator-hexpm, plus evaluator-glob fail-closed)"
  - "CONTRIBUTING 15-check branch-protection roster in ci.yml order"
affects: [221-04]
tech-stack:
  added: []
  patterns:
    - "name controls anchor on job id plus the `name:` line matched by shape, never on the display name"
    - "name-first-key read through the yaml_elixir keyword reader (last element of each reversed job list)"
key-files:
  created: []
  modified:
    - .github/workflows/ci.yml
    - .github/workflows/browser-full.yml
    - CONTRIBUTING.md
    - guides/evaluating-threadline.md
    - guides/adoption-evidence-playbook.md
    - test/threadline/ci_workflow_parity_contract_test.exs
    - test/threadline/ci_topology_contract_test.exs
decisions:
  - "check_name_errors/2 is split into one helper per rule (and parsed_job_keywords/1 beside parsed_job_order/1) so credo's nesting and complexity checks stay clean."
  - "CONTRIBUTING's 'Exact labels depend on GitHub's UI' hedge was dropped: the roster is now the exact posted names, pinned by rule=roster. A sentence pointing at the parity test replaces it."
  - "browser-full.yml job name became `Example app browser E2E (all projects)` for symmetry (D-04 discretion); workflow name and both TITLE_PREFIX values unchanged."
metrics:
  duration: "about 25 min"
  completed: 2026-09-29
estimate:
  tokens: 100000
  tasks: 3
actuals:
  tokens: 9100  # chars/4 over the realized diff (36509 chars)
  tasks: 3
  commits: 1
plan_head_before: ba3c721220b486ab78e9b1e9754b8933185b11e7
plan_head_after: 194eee6a78df0074f7e879c17f3b85ce99ae665c
---

# Phase 221 Plan 03: One-pass CI check rename Summary

Every ci.yml check now names what it proves. `Run test suite` became `Build and test` (GitHub still composes the min, current and latest suffixes), and the false `Hex evaluator smoke (threadline from hex.pm)` became `Hex package install (rehearsal registry)`. CONTRIBUTING, the two evaluator guides, the test pins and a name doc-contract changed in the same single commit.

**Milestone-branch rename SHA: 194eee6a** (`ci(221): name every CI check for what it proves (DX-01)`), carrying exactly the plan's seven paths.

## What was built

- **Task 1 (tracer, uncommitted):** verify-test's `name:` became `Build and test`. The three posted names in its leading comment were updated, with the line break before `Keys carried only via` kept in place. The verify-dialyzer timeout citation now uses the id form (`the current lane of the verify-test job of run 36258719902`), and CONTRIBUTING's timeout paragraph uses the same form. Every parity pin moved with the rename: the static-name regex, the D-17 latest-lane test with its mutations, List 2, `job_header`, the pg-tag control and the fixture. CONTRIBUTING's latest-lane paragraph, cache note and build-key note were updated too. The tracer gate re-ran parity, topology and release_control_plane: 75 tests, 0 failures.
- **Task 2 (uncommitted):**
  - D-03 facts: `mix.exs:452` reads `System.get_env("THREADLINE_HEX_EVALUATOR_MODE", "rehearsal")`, and `grep THREADLINE_HEX_EVALUATOR_MODE .github/workflows/*.yml` matches only `release.yml` (line 568 is a comment, line 592 sets `published`). ci.yml never sets the variable, so PRs run in rehearsal mode.
  - Nine job names changed per D-02. The evaluator step is now `Install this tree's package from a local registry and test it`.
  - The topology `evaluator mode forced to published` control is name-agnostic: it inserts `env:` above `name:`.
  - CONTRIBUTING: the ExDoc coupling quote, the truthful `verify-hex-evaluator` job-table row, and the 15-bullet roster in ci.yml order.
  - The evaluating and playbook guides now describe the local rehearsal registry (`bin/with-rehearsal-registry`), keep the `mix verify.hex_evaluator` token and drop the false `~> 0.11.0` literal.
  - The three parity fixtures were renamed. The browser-full job name was changed.
  - The seven affected contract files: 119 tests, 0 failures.
- **Task 3 (commit 194eee6a):**
  - `check_name_errors/2` has eight rules.
  - The test `renaming a check back or breaking the roster turns the name contract red` runs nine controls: the pre-221 credo name (name-exact and name-retired), `${{ matrix.lane }}` on the verify-test name (name-static), `Run Credo` (name-verb), a 49-character name (name-length), `Tier A` and `Lane` in a name (name-jargon), `timeout-minutes: 5` moved above `name:` (name-first-key), a dropped roster bullet (roster), and `Run test suite (current)` in a CONTRIBUTING sentence (name-retired). Each control asserts that the input changed, that no `rule=yaml-parse` error appears and that the expected fragment is reported.
  - `evaluator docs never claim the public registry (D-03)` checks README, every guide and CONTRIBUTING, with one appended-line control.
  - The live browser-full job name is asserted.

## Verification

- `mix verify.test`: 9 properties, 2515 tests, 0 failures, 3 excluded (139.9 s)
- `mix format --check-formatted`: clean. `mix verify.credo`: no issues found
- `time-to-red.py check`: `time-to-red order matches`, exit 0 (no job moved)
- `bin/verify-repo-hygiene`: 4110 tracked text files clean
- `grep -c '^    name: ' ci.yml` = 14; `name: CI` and `CI required` byte-identical; `lane: [min, current, latest]` unchanged; job ids unchanged
- `git grep -c 'Hex-published'` across the two guides and CONTRIBUTING: 0
- `/tmp/221-rename-files.txt` lists exactly the seven plan paths; the commit has no deletions

## Deviations from Plan

None. The plan was executed as written. Red-first evidence for Task 3 comes from the mutation controls, including a control that restores the pre-221 credo name. The unrenamed tree was not re-run separately, because the single-commit rule meant no pre-rename state was committed.

## Known Stubs

None.

## Threat Flags

None. T-221-09 (`CI required` untouched, gate-name rule green), T-221-10 (truthful evaluator name and step, ci.yml never sets the mode), T-221-11 (id/shape anchors, `refute mutated == input` in every harness) and T-221-12 (three doc lines rewritten, `evaluator_doc_errors/1` with control) are mitigated as planned.

## Self-Check: PASSED

- FOUND: 194eee6a in git log
- FOUND: test/threadline/ci_workflow_parity_contract_test.exs (`defp check_name_errors(`, `rule=evaluator-hexpm`)
- FOUND: CONTRIBUTING.md (`- Formatting (\`verify-format\`)`)
- FOUND: .github/workflows/ci.yml (`name: Hex package install (rehearsal registry)`)
