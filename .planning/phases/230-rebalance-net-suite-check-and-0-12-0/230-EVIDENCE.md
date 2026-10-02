# Phase 230 Evidence — Rebalance, Net-Suite Check and 0.12.0

Scope: this document records the SUITE-04 guard-test rebalance (whole-file cuts,
line-item trims, the recorded rubric) and the rebalance's own local wall clock
before and after. Net-suite (SUITE-06) and release (REL-01) evidence are
appended by later plans in this phase.

## SUITE-04 rebalance

BASE: 4a04e4f38ea5d36f313e1b1e7ffdfbdd4fc799dc

### Before — three sequential `mix test` runs at BASE

| Run | real (s) | ExUnit summary |
|---|---|---|
| 1 | 137.44 | Finished in 136.8 seconds (13.8s async, 123.0s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 2 | 138.38 | Finished in 137.7 seconds (14.1s async, 123.6s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |
| 3 | 134.07 | Finished in 133.5 seconds (12.7s async, 120.8s sync) — 32 properties, 2768 tests, 0 failures, 3 excluded |

Median real: 137.44s. Median Finished-in: 136.8s. All three runs: 0 failures.

local, noisy: this machine's own documented load-noise floor (phase 224's
evidence doc recorded head-vs-base swings of about 52 and 56 seconds in
opposite directions from unrelated concurrent processes on the same machine)
is an order of magnitude larger than any delta this rebalance is expected to
produce, so the local figure above is read as context, not as a precise
per-test measurement.

### Whole-file cuts (D-02)

| File | Test count | Verdict |
|---|---|---|
| `test/threadline/stg_doc_contract_test.exs` | 6 | Cut whole file — all 6 tests are CONTRIBUTING/guide prose cross-references |
| `test/threadline/operator_surface/theme_doc_contract_test.exs` | 11 | Cut whole file — moduledoc self-declares pure `File.read!` + `String.contains?` against guide prose |

Neither file's assertions were relocated anywhere (D-01).

### Weight-line removal

`test/partition_weights.txt` lost exactly 2 lines (the entries for the two
deleted files above) and gained 0 lines. The three trimmed files' (Task 2)
weight lines are left untouched — a stale weight only costs partition balance.

### Doc-contract floor (D-05)

`find test \( -name '*doc_contract_test.exs' -o -name '*readme_contract_test.exs' \) | wc -l`: 37 before this plan's cuts -> 35 after, against the `bin/verify-bump-rehearsal` floor of 30. The floor itself (`bin/verify-bump-rehearsal`) was not touched.
