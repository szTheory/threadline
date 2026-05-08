---
phase: 69
plan: "69-02"
subsystem: docs
tags: [support-matrix, sigra, readme, doc-contract]
requires: ["69-01"]
provides: ["COMPAT-01"]
affects:
  - guides/upgrade-path.md
  - guides/integrations/sigra.md
  - README.md
  - examples/threadline_phoenix/README.md
  - test/threadline/upgrade_path_doc_contract_test.exs
  - test/threadline/integrations/sigra_doc_contract_test.exs
  - test/threadline/readme_doc_contract_test.exs
  - test/threadline/example_phoenix_readme_contract_test.exs
tech_stack:
  added: []
  patterns:
    - lane-oriented support matrix
    - narrow String.contains?/2 doc-contract guards
key_files:
  created:
    - .planning/phases/69-integration-contracts-and-support-matrix/69-02-SUMMARY.md
  modified:
    - guides/upgrade-path.md
    - guides/integrations/sigra.md
    - README.md
    - examples/threadline_phoenix/README.md
    - test/threadline/upgrade_path_doc_contract_test.exs
    - test/threadline/integrations/sigra_doc_contract_test.exs
    - test/threadline/readme_doc_contract_test.exs
    - test/threadline/example_phoenix_readme_contract_test.exs
decisions:
  - Support claims are expressed only through the `capture-only`, `phoenix-surface`, and `sigra-reference` lanes.
  - Sigra remains a narrow first-party reference path for Phoenix hosts that already own Sigra.
  - README delegates compatibility claims to `guides/upgrade-path.md` instead of broadening them inline.
metrics:
  completed_at: "2026-05-07"
  tasks_completed: 3
  task_commits:
    - cc027ff
    - f22ee54
    - 7081b38
---

# Phase 69 Plan 69-02: Support Lanes Summary

Rewrote the public support story around three named lanes with explicit proof language, then aligned the Sigra surfaces and doc-contract tests to that narrower claim set.

## Completed Tasks

| Task | Outcome | Commit |
| --- | --- | --- |
| 1 | Reframed `guides/upgrade-path.md` around `capture-only`, `phoenix-surface`, and `sigra-reference`; updated `README.md` to point support claims at that guide. | `cc027ff` |
| 2 | Narrowed `guides/integrations/sigra.md` and `examples/threadline_phoenix/README.md` to the current first-party `sigra-reference` lane. | `f22ee54` |
| 3 | Updated the four affected doc-contract tests to lock the new lane and reference-path wording. | `7081b38` |

## Verification

Commands run on the final tree:

- `rg -n "capture-only|phoenix-surface|sigra-reference|supported|reference|unclaimed|not claimed" guides/upgrade-path.md README.md`
  Result: matches found in `guides/upgrade-path.md` for all three lanes and claim vocabulary; `README.md` points readers to `guides/upgrade-path.md` as the canonical matrix.
- `rg -n "reference|soft-dep|soft-loaded|host-owned|supported|unclaimed|Sigra" guides/integrations/sigra.md examples/threadline_phoenix/README.md`
  Result: matches found in both docs for the narrowed Sigra reference-path wording, soft-dep posture, and host-owned boundary.
- `mix test test/threadline/upgrade_path_doc_contract_test.exs test/threadline/integrations/sigra_doc_contract_test.exs test/threadline/readme_doc_contract_test.exs test/threadline/example_phoenix_readme_contract_test.exs --max-failures 1`
  Result: 28 tests, 0 failures.

## Deviations from Plan

None. The plan was executed as written.

## Known Stubs

None.

## Threat Flags

None.

## Self-Check: PASSED

- Summary file exists at `.planning/phases/69-integration-contracts-and-support-matrix/69-02-SUMMARY.md`.
- Task commits `cc027ff`, `f22ee54`, and `7081b38` exist in git history.
