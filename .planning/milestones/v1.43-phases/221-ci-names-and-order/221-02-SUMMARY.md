---
phase: 221-ci-names-and-order
plan: 02
status: complete
subsystem: ci-contracts
tags: [ci, contracts, yaml-order, order-only-move]
requires:
  - "221-01: time-to-red.py order/check and the D-06 order"
provides:
  - "@time_to_red_order literal with provenance comment (SC-2)"
  - "parsed_job_order/1: job ids in YAML order through yaml_elixir keyword mode"
  - "ci_order_errors/1 (rules order, order-last, order-unknown, order-needs, order-reader, order-merge-key)"
  - "reorder-ci-jobs.py apply/prove (chunk mover and line/chunk multiset proof)"
  - "ci.yml jobs in D-06 order, header roster line reordered to match"
affects: [221-03, 221-04]
tech-stack:
  added: []
  patterns:
    - "order read through yaml_elixir maps_as_keywords (prepend-reversed), cross-checked against the map reader"
    - "order-only YAML move proven three ways: parsed ==, sorted line multiset, per-job chunk multiset"
key-files:
  created:
    - .planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py
  modified:
    - .github/workflows/ci.yml
    - test/threadline/ci_workflow_parity_contract_test.exs
decisions:
  - "ci_order_errors/1 is split into order_guard/unknown/exact/last/needs helpers so credo's complexity and nesting checks stay clean. The rules are the RESEARCH Pattern 2 probe."
  - "ci_required_block/0 in the topology test and the release_control_plane split stay text-based; rule order-last now pins the ci-required-is-last assumption they rely on (D-10 discretion)."
  - "The needs controls anchor on the verify-test header plus its 4-space comment lines and the first `    name:` line, matched by shape, so plan 03's rename cannot make them no-ops."
metrics:
  duration: "about 20 min"
  completed: 2026-09-28
estimate:
  tokens: 100000
  tasks: 3
actuals:
  tokens: 15000  # chars/4 over the realized diff (about 60k chars; ci.yml is about 45k of it as moved lines)
  tasks: 3
  commits: 3
plan_head_before: 122603180d5bd993f33da97bc7a6aff8402e05ff
plan_head_after: 24b7a2b28d89616fa21bc36d4f618ab231de9522
---

# Phase 221 Plan 02: Job order contract and the order-only ci.yml move Summary

ci.yml's 14 jobs now read top to bottom in the D-06 measured time-to-red order, with ci-required last. The move is its own ci.yml-only commit, proven three ways, and a parsed-YAML contract with seven mutation controls pins it. The order is for readability only: YAML order has no runtime effect (D-05).

## What was built

- **Task 1 (tracer, not committed on its own, per RESEARCH Pitfall 6):** `@time_to_red_order` (the `time-to-red.py order` literal plus a comment giving the metric, the 10 run IDs, the regenerate command, the re-derive rule and "Readability only"), `parsed_job_order/1` next to `parse_yaml/1`, `ci_order_errors/1`, and the describe block `job order, check names and CI required (DX-01)` with the SC-2 test and the a,b,c fixture test. Red-first evidence on the unmoved ci.yml (`/tmp/221-order-red.txt`): `45 tests, 1 failure`, the order test only, with

  ```
  ["rule=order: expected [\"verify-release-shape\", \"verify-repo-hygiene\", \"verify-format\", \"verify-deps-audit\", \"verify-compile-no-optional\", \"verify-hex-evaluator\", \"verify-pgbouncer-topology\", \"verify-credo\", \"verify-bump-rehearsal\", \"verify-dialyzer\", \"verify-test\", \"verify-capture\", \"verify-example-browser\", \"ci-required\"], got [\"verify-format\", \"verify-credo\", \"verify-dialyzer\", \"verify-compile-no-optional\", \"verify-test\", \"verify-hex-evaluator\", \"verify-example-browser\", \"verify-capture\", \"verify-pgbouncer-topology\", \"verify-release-shape\", \"verify-bump-rehearsal\", \"verify-deps-audit\", \"verify-repo-hygiene\", \"ci-required\"]"]
  ```

  The a,b,c fixture test passed in the same run.
- **Task 2:** `reorder-ci-jobs.py` (stdlib). `chunks(text)` returns `{id: chunk}`, where a chunk is the header plus the column-2 comments and blanks directly above it plus its body. `apply` rewrites the jobs in D-06 order and rewrites header line 2. `prove` checks the line multiset and the chunk dicts.
  - ORDER_SHA **c72e13a7** (`ci(221): order ci.yml jobs by measured time-to-red (order only)`): `git show --name-only` lists only `.github/workflows/ci.yml`.
  - Mover SHA **d43dc728** (`docs(221): add the order-only job mover and its proof`): lists only the mover.
  - Proof 1: `parsed maps equal` (yaml_elixir, parent vs moved).
  - Proof 2: `line multiset: only the header roster line differs` (1115 lines before and after).
  - Proof 3: `chunk multiset: 14 chunks equal`.
  - `grep -c '^[-+]      - verify-'` over the move diff prints `0`, so ci-required's `needs:` entries did not move. The tombstone comments went with verify-release-shape and the `if: always()` explanation went with ci-required, as RESEARCH predicted.
  - The 13-file ci.yml-reader sweep: 204 tests, 0 failures.
- **Task 3 (24b7a2b2):** the test `moving or chaining jobs turns the order contract red (D-10)` has seven controls: verify-format moved above ci-required (`rule=order:`), ci-required moved above verify-repo-hygiene (`rule=order:` and `rule=order-last`), with both moves asserted `parse_yaml(moved) == parse_yaml(ci)`; `needs` on verify-test in block, flow and quoted `"Needs"` form (`rule=order-needs`); a quoted `"verify-extra":` stub (`rule=order-unknown`); a jobs-level `<<: *stub` (`rule=order-merge-key`). Each control asserts that the input changed and that no error is `rule=yaml-parse`.

## Verification

- `mix test` over the parity, topology and release_control_plane contract files: 75 tests, 0 failures
- `time-to-red.py check`: `time-to-red order matches`, exit 0
- `mix format --check-formatted && mix verify.credo`: clean (credo found no issues)
- `bin/verify-repo-hygiene`: 4108 tracked text files clean
- Commit messages since 27e4ac61: 0 matches for speed claims about red

## Deviations from Plan

None. The plan was executed as written. The only design choice was splitting `ci_order_errors/1` into helpers to stay under credo's complexity limit, recorded under decisions.

## Known Stubs

None.

## Threat Flags

None. T-221-06 (`order-needs` with block, flow and quoted controls), T-221-07 (three proofs and a ci.yml-only commit) and T-221-08 (reader-agreement, duplicate and `<<` guards plus the a,b,c fixture) are mitigated as planned.

## Self-Check: PASSED

- FOUND: .planning/phases/221-ci-names-and-order/tools/reorder-ci-jobs.py (`def chunks`)
- FOUND: test/threadline/ci_workflow_parity_contract_test.exs (`defp ci_order_errors(`, `maps_as_keywords: true`)
- FOUND: c72e13a7, d43dc728, 24b7a2b2
